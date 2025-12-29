
:global danteVID 22
:global mgmtVID  98

/system/identity/set name=Dante-PoE-QoS
/tool/romon/set enabled=yes

:global supportedModel do={
    :local model [/system/routerboard/get model]
    :local supported ($model~"^CRS[12]")
    :if (!$supported) do={
        :put "Unsupported switch model - sorry, cannot configure"
    }
    :return $supported
}

#
#  sigh, this used to be necessary in the past ..
#
:global waitForInterfaces do={
    :local i 0
    :local found false
    :do {
        :set found ([:len [/interface/ethernet find]] > 0)
        :if (!$found) do={
            :set i ($i+1)
            :log info message="Waiting for interfaces ... $i"
            :delay 1s
        } else= {
            :log info message="Interfaces available"
        }
    } while (i<20 && !$found)
    :return $found
}

:if ([$supportedModel] && [$waitForInterfaces]) do={

    #
    #  Build default lists of ethernet and sfp interface names
    #
    #  The typical default Mikrotik config bridges traffic to the switch CPU,
    #  which is not very powerful and can get overloaded from Dante multicast.
    #  If you're load testing with multicast, the switch CPU hits 100% PDQ.
    #
    #  We use VLANs to keep multicast from hitting the switch CPU, something like:
    #  - etherN: untagged vlan22 Dante network, mgmt vlan98 tagged
    #  -   sfpN: untagged vlan98 management network only
    #
    :global ethNames [:toarray ""]
    :global sfpNames [:toarray ""]
    {
        :local i nil
        :foreach i in [/interface ethernet find where default-name~"^ether"] do={
            :set ethNames ($ethNames, [/interface ethernet get $i default-name])
        }
        :foreach i in [/interface ethernet find where default-name~"^sfp"] do={
            :set sfpNames ($sfpNames, [/interface ethernet get $i default-name])
        }
        #/environment print
    }

    ##
    ##  Optionally override the above defaults if you don't like them
    ##
    #:global danteNames [:toarray "ether3,ether4,ether5"]
    #:global mgmtNames [:toarray "sfp9"]
    :global danteNames ($ethNames)
    :global mgmtNames  ($sfpNames)

    /interface bridge add name=bridge1
    /interface bridge port
    {
        :local ifName nil
        :foreach ifName in ($danteNames,$mgmtNames) do={
            add bridge=bridge1 interface=$ifName hw=yes
        }
    }

    /interface vlan
    add interface=bridge1 name="MGMT-vlan$mgmtVID" vlan-id=$mgmtVID
    /ip dhcp-client
    add disabled=no interface="MGMT-vlan$mgmtVID"

    #
    #  VLAN configuration - defend the switch CPU from multicast!
    #
    # ingress - map untagged (i.e. VLAN=0) received packets to VLANs
    /interface ethernet switch ingress-vlan-translation
    add customer-vid=0 new-customer-vid=$danteVID ports=$danteNames
    add customer-vid=0 new-customer-vid=$mgmtVID ports=$mgmtNames
    # port VLAN membership
    /interface ethernet switch vlan
    add ports=$danteNames vlan-id=$danteVID
    add ports=($danteNames,$mgmtNames,"switch1-cpu") vlan-id=$mgmtVID
    # egress - remove/keep VLAN tags as necessary
    # Note: untagged vlan-id=$danteVID ports need an entry!
    /interface ethernet switch egress-vlan-tag
    add vlan-id=$danteVID
    add tagged-ports=("switch1-cpu",$danteNames) vlan-id=$mgmtVID

    /interface ethernet switch
    set drop-if-invalid-or-src-port-not-member-of-vlan-on-ports=("switch1-cpu", $danteNames,$mgmtNames)

    #
    #  Dante QoS configuration
    #
    /interface ethernet switch dscp-qos-map
    set 8 priority=4
    set 46 priority=5
    set 56 priority=6

    /interface ethernet switch port
    {
        :local ifName nil
        :foreach ifName in ($danteNames, $mgmtNames) do={
            :log info message=("Applying Dante QoS to: " . $ifName)
            set $ifName per-queue-scheduling="strict-priority:0,strict-priority:0,strict-priority:0,strict-priority:0,strict-priority:0,strict-priority:0,strict-priority:0,strict-priority:0"
            set $ifName priority-to-queue=0:0,1:1,2:2,3:3,4:4,5:5,6:6,7:7
            set $ifName qos-scheme-precedence=dscp-based
        }
    }
}
