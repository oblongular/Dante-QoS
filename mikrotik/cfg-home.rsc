{
    :local s [/system/routerboard/get serial-number]
    :local n "Dante-QoS-VLAN"
    :if ($s = "HEG08HS7MZ3")  do={ :set n "PoE8-Printer"     }
    :if ($s = "HEG08GETNAW")  do={ :set n "PoE8-TestDevice"  }
    :if ($s = "D2610C8BA260") do={ :set n "PoE8-AudioRoom"   }
    
    /system/identity/set name=$n
    /tool/romon/set enabled=yes
}

:global cfg {
    "home"={
        "pvid"=22;
        "first"="ether1";
        "last"="ether8";
    }
    "TRUNK"={
        "first"="sfp9";
        "last"="sfp12";
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
