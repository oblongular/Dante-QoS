#
#  The typical default Mikrotik config bridges traffic to the switch CPU,
#  which is not very powerful and can get overloaded from Dante multicast.
#  If you're load testing with multicast, the switch CPU hits 100% PDQ.
#
#  We can use VLANs to keep multicast from hitting the switch CPU, something like:
#  - etherN: untagged vlan22 Dante network, mgmt vlan98 tagged
#  -   sfpN: untagged vlan98 management network only
#

# configuration for this script comes from a global variable
:global cfg

#
#  check that the global configuration variable exists ...
#
:local checkConfigExists do={
    :global cfg
    :local returnStatus true

    :if ([:typeof $cfg] != "array") do={
        :put "ERROR: no configuration defined"
        :put "ERROR: did you forget to /import your configuration file?"
        :set returnStatus false
    }

    :return $returnStatus
}

#
#  check we're configuring a supported switch
#
#  We're using QoS Phase 2 - QoS Enforcement
#  (introduced in RouterOS v7.13 for 98DX224S, 98DX226S, and 98DX3236 switch chips)
#  Manual says CRS3xx/5xx - but that is not specific enough (as at 2024-01-03)
#
:local supportedModel do={

    :local supportedSwitches {
        "Marvell-98DX3236"=true;
        "Marvell=98DX226S"=true;
        "Marvell-98DX224S"=true;
    }
    :local s false

    :if ($supportedSwitches->[/interface/ethernet/switch/get switch1 type]) do={
        :set s true
    }
    :return $s
}

#
#  wait for interfaces to appear
#  (this used to be necessary at boot time..)
#
:local waitForInterfaces do={
    :local i 0
    :local found false
    :do {
        :set found ([:len [/interface/ethernet find]] > 0)
        :if (!$found) do={
            :set i ($i+1)
            :log info message="Waiting for interfaces ... $i"
            :delay 1s
        } else={
            :log info message="Interfaces available"
        }
    } while (i<20 && !$found)
    :return $found
}

#
#  convert the cfg structure into readily useable interface lists
#  check for some basic misconfiguration in the config
#
#  RESULT: hangs lists of tagged/untagged interface names off each net cfg
#
:local buildIfList do={

    :global cfg
    :local returnStatus true
    :local allEtherNames [:toarray ""]
    :local chkVIDs [:toarray ""]
    :local chkIntfs [:toarray ""]

    :if (([:typeof ($cfg->"MGMT"->"pvid")]) != "num") do={
        :put "ERROR: 'MGMT' network with at least one port/pvid is required"
        :put "ERROR: connect to this port with a computer to run Winbox"
        :return false
    }

    :foreach i in [/interface/ethernet find] do={
        :set $allEtherNames ($allEtherNames, [/interface/ethernet/get $i default-name])
    }

    :foreach netName,netCfg in $cfg do={
        :local ifirst -1
        :local ilast -1

        :put "Checking config '$netName'"
        :for i from=0 to=([:len $allEtherNames]-1) step=1 do={
            :local n ($allEtherNames->$i)
            :if ($n = $netCfg->"first") do={
                :set ifirst $i
            }
            :if ($n = $netCfg->"last") do={
                :set ilast $i
            }
        }

        :if ($netName = "TRUNK") do={
            :if ([:typeof ($cfg->"TRUNK"->"pvid")] != "nothing") do={
                :if (($cfg->"TRUNK"->"pvid") != 1) do={
                    :put "ERROR: 'TRUNK' should not include a pvid (default pvid=1 will be used)"
                    :set returnStatus false
                }
            }
            :set ($cfg->"TRUNK"->"pvid") 1
        }

        :if ($ifirst >= 0 && $ilast >= 0 && $ilast >= $ifirst) do={
            #:put ("  -> _if_list[$ifirst..$ilast]")
            :set ($cfg->$netName->"_if_list") \
                [:pick $allEtherNames $ifirst (1+$ilast)]
        } else={
            :if (($netCfg->"first" = "TAGGED-ONLY") && ($netCfg->"last" = "TAGGED-ONLY")) do={
                # no untagged/pvid ports for this VLAN
                #:put ("  -> TAGGED-ONLY")
                :set ($cfg->$netName->"_if_list") [:toarray ""]
            } else={
                :put ("\n### ERROR: bad config for '$netName': '" . $netCfg->"first" . "' or '" . $netCfg->"last" . "' cannot be found or are out of order")
                :set returnStatus false
            }
        }

        # check for re-use of vlan-ids
        :local vidStr [:tostr ($cfg->$netName->"pvid")]
        :set ($chkVIDs->$vidStr) (1 + ($chkVIDs->$vidStr))
        :foreach v,c in $chkVIDs do={
            :if ($c > 1) do={
                :put "ERROR: pvid=$v appears more than once in cfg"
                :set returnStatus false
            }
        }
        # check for re-use of interface names
        :foreach i in=($cfg->$netName->"_if_list") do={
            :set ($chkIntfs->$i) (1 + ($chkIntfs->$i))
        }
        :foreach i,c in $chkIntfs do={
            :if ($c > 1) do={
                :put "ERROR: $i appears more than once in cfg"
                :set returnStatus false
            }
        }
    }

    :foreach netName,netCfg in $cfg do={
        :local taggedPorts [:toarray ""]

        :if ($netName != "TRUNK") do={
            # trunk ports carry this VLAN tagged (by definition)
            :set taggedPorts ($cfg->"TRUNK"->"_if_list")

            # mgmt network is a special case, it goes tagged to the switch-cpu port
            :if ($netName = "MGMT") do={
                :if ([/system/routerboard/get model] ~ "^CRS[12]") do={
                   :set taggedPorts ("switch1-cpu", $taggedPorts)
                } else={
                   :set taggedPorts ("bridge1", $taggedPorts)
                }
            }

            # non-trunk ports can carry this VLAN tagged, if specified
            :foreach otherName,otherCfg in $cfg do={
                :if (($otherName != $netName) and ($otherName != "TRUNK")) do={
                    :if ($netCfg->"add-tagged-to-others") do={
                        :set taggedPorts ($taggedPorts, $otherCfg->"_if_list")
                    }
                }
            }

            :set ($cfg->$netName->"_tagged_ports") $taggedPorts
        }

        :put "\nNetwork '$netName':"
        :put ("  -> pvid=" . ($cfg->$netName->"pvid"))
        :put ("  -> untagged[" . [:tostr ($cfg->$netName->"_if_list")] . "]")
        :put ("  -> tagged[" . [:tostr ($cfg->$netName->"_tagged_ports")] . "]")
    }

    :return $returnStatus
}


:if ([$checkConfigExists] && [$supportedModel] && [$waitForInterfaces] && [$buildIfList]) do={

    :local mgmtVID ($cfg->"MGMT"->"pvid")

    /interface bridge
    add name=bridge1 frame-types=admit-only-vlan-tagged

    /interface vlan
    add interface=bridge1 name="MGMT-vlan$mgmtVID" vlan-id=$mgmtVID
    /ip dhcp-client
    add disabled=no interface="MGMT-vlan$mgmtVID"

    :put "\nVLAN configuration starting ..."
    #
    #  VLAN configuration - defend the switch CPU from multicast!
    #
    /interface bridge port
    {
        :foreach netName,netCfg in $cfg do={
            :local vlanID ($netCfg->"pvid")
            :foreach ifName in ($netCfg->"_if_list") do={
                :put "$netName: $ifName pvid=$vlanID"
                add bridge=bridge1 interface=$ifName pvid=$vlanID frame-types=admit-all hw=yes
            }
        }
    }

    /interface bridge vlan
    {
        :foreach netName,netCfg in $cfg do={
            :if ($netName != "TRUNK") do={
                add bridge=bridge1 tagged=($cfg->$netName->"_tagged_ports") vlan-ids=($netCfg->"pvid")
            }
        }
        
        :put "\nEnabling VLAN filtering (will likely disconnect winbox)"
        /interface/bridge/set bridge1 vlan-filtering=yes ingress-filtering=yes
    }

    {
        :put "\nQoS configuration starting ..."
        #
        #  Dante QoS configuration
        #
        #  Docs said traffic-class 6 is strict priority, above "highest"
        #  traffic-class 5 is "high priority" - guaranteed before "low priority"
        #  Port stats don't show pkt count for tc7 - hence using 5,6 (vs 6,7) - bug?
        #
        #  Check /interface/ethernet/switch/qos/tx-manager/queue/print
        #  /interface/ethernet/switch/qos/port> print stats where name=ether2
        #
        /interface ethernet switch qos profile
        add dscp=46 name=dante-audio traffic-class=5
        add dscp=56 name=dante-ptp traffic-class=6

        /interface ethernet switch qos map ip
        add dscp=46 profile=dante-audio
        add dscp=47 profile=default
        add dscp=56 profile=dante-ptp
        add dscp=57 profile=default

        # don't be too clever - trust DSCP on all ports
        /interface ethernet switch qos port
        {
            :foreach i in [find where profile] do={
                :put ([get number=$i name] . " --> trust DSCP/keep")
                set $i trust-l3=keep
            }
        }

        /interface ethernet switch
        set switch1 qos-hw-offloading=yes
    }

    :put "\nAll done."
}
