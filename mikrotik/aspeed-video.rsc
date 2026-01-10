#
# very basic switch configuration for aspeed devices
# protect the switch CPU from multicast
# jumbograms are required
#

/system/identity/set name=aspeed-video

# mgmt access is via sfp4 (which is pvid=1 by default and has switch CPU access)
/ip/dhcp-client/add interface=sfp-sfpplus4

/interface/bridge/add name=br0 frame-types=admit-only-vlan-tagged ingress-filtering=yes vlan-filtering=yes

# sfp1 is the fibre port between front & back of church
:global ifNames [:toarray "sfp-sfpplus1"]
:foreach i in [/interface/ethernet/find where default-name~"^ether"] do={
    :set ifNames ($ifNames, [/interface/ethernet/get $i default-name])
}
:foreach i in $ifNames do={
    :put "Adding $i to br0 .."
    /interface/bridge/port/add bridge=br0 interface="$i" pvid=55 frame-types=admit-only-untagged-and-priority-tagged
}

# jumbograms all the way
/interface/ethernet/set l2mtu=10218 mtu=9000 [find]

/tool romon set enabled=yes
