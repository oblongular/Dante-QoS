# handy: /system/reset-configuration keep-users=yes no-defaults=yes

/system identity
set name=L2-switch-with-NAT

# the last SFP port will be the NAT/upstream internet connection
:global sfplist [/interface/ethernet/find where default-name~"^sfp"]
:global natPort [/interface/ethernet/get ($sfplist->([:len $sfplist] - 1)) name]

# L2 bridge/switch configuration
/interface/bridge/add name=br_lan
/interface/ethernet
:foreach i in=[find] do={
    :local ifname [get $i name]
    :if ($ifname != $natPort) do={
        /interface/bridge/port/add bridge=br_lan interface=$ifname
    }
}

# downstream - local LAN configuration
/ip address
add address=172.16.151.1/24 interface=br_lan network=172.16.151.0
/ip pool
add name=dhcp_pool0 ranges=172.16.151.10-172.16.151.127
/ip dhcp-server
add address-pool=dhcp_pool0 interface=br_lan name=dhcp1
/ip dhcp-server network
add address=172.16.151.0/24 dns-server=1.1.1.1 gateway=172.16.151.1

# upstream - NAT to the internet configuration
/ip dhcp-client
add default-route-tables=main interface=$natPort
/ip firewall nat
add action=masquerade chain=srcnat out-interface=$natPort
