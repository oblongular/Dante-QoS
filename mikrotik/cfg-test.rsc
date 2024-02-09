/system/identity/set name=Dante-QoS-VLAN
/tool/romon/set enabled=yes

:global cfg {
    "home"={
        "pvid"=22;
        "first"="ether1";
        "last"="ether6";
    }
    "MGMT"={
        "pvid"=98;
        "first"="ether7";
        "last"="ether8";
        "add-tagged-to-others"=true;
    }
    "TRUNK"={
        "first"="sfp9";
        "last"="sfp12";
    }
    "iot"={
        "pvid"=100;
        "first"="TAGGED-ONLY";
        "last"="TAGGED-ONLY";
        "add-tagged-to-others"=true;
    }
}

#
#  Boilerplate code - LEAVE THIS ALONE!
#
{
    :local m [/system/routerboard/get model]
    :local f
    :if ($m ~ "^CRS[12]") do={
        :set f "dante-qos-mikrotik-crs1xx2xx.rsc"
    }
    :if ($m ~ "^CRS[35]") do={
        :set f "dante-qos-mikrotik-crs3xx5xx.rsc"
    }
    :local i [/file/find where name~"$f\$"]
    :if ([:len $i] != 1) do={
        :put "ERROR: could not locate EXACTLY ONE script called '$f' .."
    } else={
        /import [/file/get $i name]
    }
}
