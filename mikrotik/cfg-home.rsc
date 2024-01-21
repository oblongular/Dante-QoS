/system/identity/set name=Dante-QoS-VLAN
/tool/romon/set enabled=yes

:global cfg {
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
    "home"={
        "pvid"=22;
        "first"="ether1";
        "last"="ether24";
    }
}
