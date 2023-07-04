#!/usr/bin/env expect

###[ TEST PROCS ]################################
proc test_level_parsing {ldata_name} {
  set parsing_list ""
  set num_tests_failed 0
  set num_tests_per_level 3
  set CLR_FMT "\033\[0;0m"
  set FMT_RED "\033\[0;31m"
  set FMT_GRN "\033\[0;32m"
  set FMT_BLUE "\033\[0;34m"
  set FMT_PURP "\033\[0;35m"
  set LDATA_NAME_FQ [format {::%s} $ldata_name]
  set level_regex { *([[:alpha:]]+) *([[:digit:]]+) *}

  foreach {lname} [lsort [array names $LDATA_NAME_FQ]] {
    set test_failure_present 0

    for {set i 0} {$i < $num_tests_per_level} {incr i} {
      set lmax [lindex [lindex [array get $LDATA_NAME_FQ $lname] 1] 1]
      set randnum [expr {int(rand() * $lmax)}]

      if {$i == 1} {set randnum [expr {$randnum + 40}]}
      set testlevel "$lname$randnum"

      if {[regexp $level_regex $testlevel -> sub1 sub2]} {
        set levelname [string tolower $sub1]
        # Strip leading zeroes that can cause unintended octal interpretation
        scan $sub2 {%d} levelnum
        lappend parsing_list "$testlevel|$levelname|$levelnum"
      } else {
        set test_failure_present 1
        incr num_tests_failed
        lappend parsing_list "${FMT_RED}$testlevel|FAILED${CLR_FMT}"
      }
    }

    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    puts "\[${FMT_PURP}\+${CLR_FMT}] ${FMT_BLUE}TEST LEVEL PARSING${CLR_FMT}"
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    if {$test_failure_present} {
      puts "\[${FMT_RED}FAILED${CLR_FMT}] [join $parsing_list " "]"
    } else {
      puts "\[${FMT_GRN}PASSED${CLR_FMT}] [join $parsing_list " "]"
    }
    set parsing_list ""
  }

  if {$num_tests_failed != 0} {
    set tst_word [expr {$num_tests_failed == 1 ? "TEST" : "TESTS"}]
    puts "\[${FMT_RED}$num_tests_failed $tst_word FAILED${CLR_FMT}\]"
  } else {
    puts "\[${FMT_GRN}ALL TESTS PASSED${CLR_FMT}\]"
  }
}

proc get_var_info {varLabel varValue labelLen} {
  set CLR_FMT         "\033\[0;0m"
  set FMT_LRED        "\033\[0;91m"
  set FMT_LGRN        "\033\[0;92m"
  set FMT_LPURP       "\033\[0;95m"
  set FMT_LCYAN       "\033\[0;96m"
  set defaultValLen   48
  set defaultLabelLen 40
  set type_RE {value is a (.+) with a refcount}

  if {$labelLen > $defaultLabelLen} {set labelLen $defaultLabelLen}

  set type_str [::tcl::unsupported::representation $varValue]
  if {! [regexp $type_RE $type_str -> type]} {
    return [format "%-${labelLen}s ${FMT_LRED}%9s${CLR_FMT} %s" $varLabel "unknown" $varValue]
  }

  if {$type eq "pure string" && [string length $varValue] == 0} {
    return [format "%-${labelLen}s ${FMT_LPURP}%9s${CLR_FMT} \"\"" $varLabel "string"]
  } elseif {($type eq "pure string" && [string is integer $varValue]) ||
             $type eq "integer" ||
             $type eq "int"} {
    return [format "%-${labelLen}s ${FMT_LGRN}%9s${CLR_FMT} %d" $varLabel "integer" $varValue]
  } elseif {($type eq "pure string" && [string is double $varValue]) ||
             $type eq "double"} {
    return [format "%-${labelLen}s ${FMT_LCYAN}%9s${CLR_FMT} %.2f" $varLabel "double" $varValue]
  } elseif {($type eq "pure string" || $type eq "string" || $type eq "path") &&
             [string length $varValue] > $defaultValLen} {
    set strItem [format "%s..." [string range $varValue 0 [expr {$defaultValLen - 4}]]]
    return [format "%-${labelLen}s ${FMT_LPURP}%9s${CLR_FMT} %s" $varLabel "string" $strItem]
  } elseif {$type eq "pure string" || $type eq "string" || $type eq "path"} {
    return [format "%-${labelLen}s ${FMT_LPURP}%9s${CLR_FMT} %s" $varLabel "string" $varValue]
  } elseif {[string length $varValue] > ${defaultValLen}} {
    set strItem [format "%s..." [string range $varValue 0 [expr {$defaultValLen - 4}]]]
    return [format "%-${labelLen}s %9s %s" $varLabel $type $strItem]
  }

  set newlist ""
  if {$type eq "list" && [llength $varValue] > 1} {
    set idx 0
    foreach {lst_item} [lrange $varValue 0 end] {
      lappend newlist [get_var_info "$varLabel\[$idx\]" $lst_item $labelLen]
      incr idx
    }
    return $newlist
  } elseif {$type eq "list" && [llength $varValue] == 1} {
    return [get_var_info "$varLabel\[0\]" [lindex $varValue 0] $labelLen]
  }

  return [format "%-${labelLen}s %9s %s" $varLabel $type $varValue]
}

proc get_max_field_widths {{ns ::}} {
  set pat [set ns]::*
  set arrVarsList     ""
  set lstVarsList     ""
  set genVarsList     ""
  set maxLensList     ""
  set arrMaxLabelLen   0
  set lstMaxLabelLen   0
  set genMaxLabelLen   0
  set defaultLabelLen 40
  set type_RE {value is a (.+) with a refcount}

  foreach {var} [info vars $pat] {
    # Handle array vars
    if {[array exists $var]} {
      # Plus 2 for parentheses
      set arrNameLen [expr [string length $var] + 2]
      set maxLabelLen 0

      foreach {key} [array names $var] {
        set currLabelLen [expr [string length $key] + $arrNameLen]
        if {$currLabelLen > $maxLabelLen} {set maxLabelLen $currLabelLen}
      }

      lappend arrVarsList "$var"
      if {$maxLabelLen > $arrMaxLabelLen} {set arrMaxLabelLen $maxLabelLen}
      continue
    }

    set type_str [::tcl::unsupported::representation [set $var]]
    if {! [regexp $type_RE $type_str -> type]} {
      set currLabelLen [string length $var]
      if {$currLabelLen > $genMaxLabelLen} {set genMaxLabelLen $currLabelLen}
      lappend genVarsList "$var"
      continue
    }

    # Handle list vars
    if {$type eq "list" && [llength [set $var]] > 0} {
      # Plus 2 for parentheses + max index character-length
      set maxLabelLen [expr [string length $var] + 2 + [string length [llength [set $var]]]]
      if {$maxLabelLen > $lstMaxLabelLen} {set lstMaxLabelLen $maxLabelLen}
      lappend lstVarsList "$var"
      continue
    }

    # Handle all other vars
    set currLabelLen [string length $var]
    if {$currLabelLen > $genMaxLabelLen} {set genMaxLabelLen $currLabelLen}
    lappend genVarsList "$var"
    continue
  }

  set overallMaxLen $arrMaxLabelLen
  if {$overallMaxLen < $lstMaxLabelLen}  {set overallMaxLen $lstMaxLabelLen}
  if {$overallMaxLen < $genMaxLabelLen}  {set overallMaxLen $genMaxLabelLen}
  if {$overallMaxLen > $defaultLabelLen} {set overallMaxLen $defaultLabelLen}

  foreach {item} $arrVarsList {lappend maxLensList [list $item $overallMaxLen]}
  foreach {item} $lstVarsList {lappend maxLensList [list $item $overallMaxLen]}
  foreach {item} $genVarsList {lappend maxLensList [list $item $overallMaxLen]}
  return $maxLensList
}

proc print_all_vars {{ns ::}} {
  set pat [set ns]::*
  set arrVarsList ""
  set lstVarsList ""
  set genVarsList ""
  set CLR_FMT     "\033\[0;0m"
  set FMT_BLUE    "\033\[0;34m"
  set FMT_PURP    "\033\[0;35m"
  set FMT_LRED    "\033\[0;91m"
  set type_RE {value is a (.+) with a refcount}

  set maxList [concat {*}[get_max_field_widths]]
  array set labelLen $maxList

  set all_vars [lsort [info vars $pat]]
  foreach {var} $all_vars {
    # Handle array vars
    if {[array exists $var]} {
      set arrNames [lsort [array names $var]]
      foreach {key} $arrNames {
        lappend arrVarsList [get_var_info "$var\($key\)" [lindex [array get $var $key] 1] $labelLen($var)]
      }
      continue
    }

    set type_str [::tcl::unsupported::representation [set $var]]
    if {! [regexp $type_RE $type_str -> type]} {
      lappend genVarsList [format "%${labelLen($var)}s ${FMT_LRED}%s${CLR_FMT} %s" $var "unknown" [set $var]]
      continue
    }

    # Handle list vars
    if {$type eq "list" && [llength [set $var]] > 0} {
      set idx 0
      foreach {lst_item} [set $var] {
        lappend lstVarsList [get_var_info "$var\[$idx\]" $lst_item $labelLen($var)]
        incr idx
      }
      continue
    } else {
      # Handle all other vars
      lappend genVarsList [get_var_info "$var" [set $var] $labelLen($var)]
    }
  }

  puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  puts "\[${FMT_PURP}\+${CLR_FMT}] ${FMT_BLUE}ALL VARIABLES${CLR_FMT}"
  puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  if {[llength $arrVarsList] > 0} {foreach {arrItem} $arrVarsList {puts $arrItem}}
  if {[llength $lstVarsList] > 0} {foreach {lstItem} $lstVarsList {puts $lstItem}}
  if {[llength $genVarsList] > 0} {foreach {genItem} $genVarsList {puts $genItem}}
  return
}

proc print_all_namespaces {{ns ::}} {
  puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  puts "\[${FMT_PURP}\+${CLR_FMT}] ${FMT_BLUE}ALL NAMESPACES${CLR_FMT}"
  puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  puts [list "namespace" $ns]
  foreach child [namespace children $ns] {puts [list "namespace" $child]}
  return
}
