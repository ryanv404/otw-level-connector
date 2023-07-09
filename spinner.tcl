#!/usr/bin/env expect

set SPINNER_LEN 3
set MSG [lindex $::argv 0]
set HAS_TPUT 0

trap {scr_cleanup $SPINNER_LEN $MSG; exit 0;} {INT QUIT}

if {[string length [auto_execok "tput"]] != 0} {
  set HAS_TPUT 1
}

proc scr_init {} {
  if {$::HAS_TPUT} {
    exec tput civis >@stdout
  } else {
    puts "ASCII hide cursor sequence"
  }
  return
}

proc scr_cleanup {len msg} {
  set strlen [string length $msg]
  set maxlen [expr {$len + $strlen + 12}]

  puts -nonewline [format "\r%s\r" [string repeat " " $maxlen]]
  flush stdout

  if {$::HAS_TPUT} {
    exec tput cnorm >@stdout
  } else {
    puts "ASCII unhide cursor sequence"
  }

  return
}

proc run_spinner {len msg} {
  set FMT_GRN "\033\[1;32m"
  set FMT_CLR "\033\[0;0m"

  set DELAY 0.1
  set SPINNER_CHARS [list "${FMT_GRN}/${FMT_CLR}" "${FMT_GRN}-${FMT_CLR}" "${FMT_GRN}\\${FMT_CLR}" "${FMT_GRN}|${FMT_CLR}"]
  set tot_frames [llength $SPINNER_CHARS]

  scr_init
  fconfigure stdin -blocking 0

  for {set i 0} {1} {incr i} {
    set frame_idx [expr {$i % $tot_frames}]
    set fmtstr [format "\[%s\] %s\r" [lindex $SPINNER_CHARS $frame_idx] $msg]

    puts -nonewline $fmtstr
    flush stdout

    sleep $DELAY
    if {[gets stdin] eq "die"} {break}
  }

  scr_cleanup "$len" "$msg"
  return
}

run_spinner "$SPINNER_LEN" "$MSG"
exit 0
