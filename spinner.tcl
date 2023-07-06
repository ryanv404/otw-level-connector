#!/usr/bin/env expect
#
# Just messing around with progress indicators in Tcl.

### CONFIGS ###
set SPINNER_LEN 10
set DELAY 0.1

### SPINNER ###
proc run_spinner {width delay} {
  set total_frames [expr {$width * 2}]
  set max_dots [expr {$width - 1}]
  set chars [list "\\" "/"]

  # Must redirect or tput operates on exec's child shell
  exec tput civis >@stdout

  for {set i 0} {$i < 30} {incr i} {
    # Dots
    set x [expr {$i % $width}]
    if {[expr {$i % $total_frames}] > $max_dots} {
      set lhs [string repeat "." [expr {$max_dots - $x}]]
      set rhs [string repeat "." $x]
      set s [lindex $chars 0]
    } else {
      set lhs [string repeat "." $x]
      set rhs [string repeat "." [expr {$max_dots - $x}]]
      set s [lindex $chars 1]
    }

    # Slash
    puts -nonewline stderr [format "\[%s%s%s\]\r" $lhs $s $rhs]
    sleep $delay
  }

  clean_up_spinner $width
  return
}

proc clean_up_spinner {width} {
  puts -nonewline stderr [format "%s\r\n" [string repeat " " [expr {$width + 2}]]]
  exec tput cnorm >@stdout
  return
}

#TODO find a way to mimic bash's `trap clean_up ERR` command to handle interruptions.

run_spinner $SPINNER_LEN $DELAY
