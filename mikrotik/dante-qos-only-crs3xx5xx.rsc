#
#  Dante QoS configuration
#
#  Docs said traffic-class 6 is strict priority, above "highest"
#  traffic-class 5 is "high priority" - guaranteed before "low priority"
#  Bug?: Port stats don't show pkt count for tc7 - hence using 5,6 (vs 6,7/strict)
#
#  Check using
#    /interface/ethernet/switch/qos/tx-manager/queue/print
#    /interface/ethernet/switch/qos/port> print stats where name=ether2
#

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

:if (false) do={
    # debugging code only - warning: removes configuration!
    /interface/ethernet/switch/qos/map/ip/remove [find]
    /interface/ethernet/switch/qos/profile/remove [find where name!="default"]
}

{
    :if [$supportedModel] do={

        /interface ethernet switch qos profile
        add dscp=46 name=dante-audio traffic-class=5
        add dscp=56 name=dante-ptp traffic-class=6

        /interface ethernet switch qos map ip
        add dscp=46 profile=dante-audio
        add dscp=47 profile=default
        add dscp=56 profile=dante-ptp
        add dscp=57 profile=default

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
}
