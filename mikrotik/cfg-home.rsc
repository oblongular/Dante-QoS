{
    :local s [/system/routerboard/get serial-number]
    :local n "Dante-QoS-VLAN"
    :if ($s = "HG909HWNVWY")  do={ :set n "PoE8-Printer"     }
    :if ($s = "HEG08GETNAW")  do={ :set n "PoE8-TestDevice"  }
    :if ($s = "D2610C8BA260") do={ :set n "PoE8-AudioRoom"   }
    :if ($s = "HGD09WD58T3")  do={ :set n "PoE8-SPARE"   }
    
    /system/identity/set name=$n
    /tool/romon/set enabled=yes
}

:global getLastEthernet do={
  :local ethList [/interface ethernet find]
  :local lastIndex ([:len $ethList] - 1)
  :return [/interface ethernet get [:pick $ethList $lastIndex] name]
}

:global cfg {
    "home"={
        "pvid"=22;
        "first"="ether1";
        "last"=[$getLastEthernet];
    }
    "MGMT"={
        "pvid"=98;
        "first"="TAGGED-ONLY";
        "last"="TAGGED-ONLY";
        "add-tagged-to-edge-ports"=true;
    }
    "iot"={
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
    :if ($m ~ "^RB5009")  do={ :set f "dante-qos-mikrotik-crs3xx5xx.rsc" }
    :local i [/file/find where name~"$f\$"]
    :if ([:len $i] != 1) do={
        :local m "ERROR: could not locate EXACTLY ONE script called '$f' .."
        :put $m
        /log/error message="$m"
    } else={
        :put "Running $f"
        /import [/file/get $i name]
    }
}
