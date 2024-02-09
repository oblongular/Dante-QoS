/system/identity/set name=Dante-QoS-VLAN
/tool/romon/set enabled=yes

:global cfg {
    "home"={
        "pvid"=22;
        "first"="ether1";
        "last"="ether24";
    }
    "TRUNK"={
        "first"="sfp-sfpplus1";
        "last"="sfp-sfpplus4";
    }
    "MGMT"={
        "pvid"=98;
        "first"="TAGGED-ONLY";
        "last"="TAGGED-ONLY";
        "add-tagged-to-others"=true;
    }
    "iot"={
        "pvid"=100;
        "first"="TAGGED-ONLY";
        "last"="TAGGED-ONLY";
        "add-tagged-to-others"=true;
    }
}

##
##  Boilerplate code - LEAVE THIS ALONE!
##
:global rbModel
:set rbModel [/system/routerboard/get model]
:if ($rbModel ~ "^CRS[12]") do={
    /import filename="dante-qos-mikrotik-crs1xx2xx.rsc"
}
:if ($rbModel ~ "^CRS[35]") do={
    /import filename="dante-qos-mikrotik-crs3xx5xx.rsc"
}
