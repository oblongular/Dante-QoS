/system/identity/set name=Dante-QV-eg8
/tool/romon/set enabled=yes

:global cfg {
    "MGMT"={
        "pvid"=98;
        "first"="ether1";
        "last"="ether1";
        "add-tagged-to-edge-ports"=true;
    }
    "comms"={
        "pvid"=20;
        "first"="ether2";
        "last"="ether2";
    }
    "dante_primary"={
        "pvid"=22;
        "first"="ether3";
        "last"="ether8";
    }
    "TRUNK"={
        "first"="sfp9";
        "last"="sfp12";
    }
    "internet"={
        "pvid"=100;
        "first"="TAGGED-ONLY";
        "last"="TAGGED-ONLY";
        "add-tagged-to-edge-ports"=true;
    }
}

#
#  Boilerplate code - pro tip: LEAVE THIS ALONE!
#
{
    :local m [/system/routerboard/get model]
    :local f "--UNSUPPORTED-MODEL--"
    :if ($m ~ "^CRS[12]") do={ :set f "dante-qos-mikrotik-crs1xx2xx.rsc" }
    :if ($m ~ "^CRS[35]") do={ :set f "dante-qos-mikrotik-crs3xx5xx.rsc" }
    :local i [/file/find where name~"$f\$"]
    :if ([:len $i] != 1) do={
        :local m "ERROR: could not locate EXACTLY ONE script called '$f' .."
        :put $m
        /log/error message="$m"
    } else={
        /import [/file/get $i name]
    }
}
