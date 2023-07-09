#!/usr/bin/env expect

set SPINNER_LEN 3
set MSG [lindex $::argv 0]
set HAS_TPUT 0
set TPUT_CMD [auto_execok "tput"]

trap {scr_cleanup "$::SPINNER_LEN" "$::MSG"; exit 0;} {INT QUIT}
if {[string length "$::TPUT_CMD"] != 0} {
  set HAS_TPUT 1
}

proc scr_init {} {
  if {$::HAS_TPUT} {
    exec "$::TPUT_CMD" civis >@stdout
  } else {
    chan puts "ASCII hide cursor sequence"
    chan flush stdout
  }
  return
}

proc scr_cleanup {len msg} {
  set strlen [string length "$msg"]
  set maxlen [expr {$len + $strlen + 12}]

  chan puts -nonewline [format "\r%s\r" [string repeat " " $maxlen]]
  chan flush stdout

  if {$::HAS_TPUT} {
    exec "$::TPUT_CMD" cnorm >@stdout
  } else {
    chan puts "ASCII unhide cursor sequence"
    chan flush stdout
  }

  return
}

proc run_spinner {len msg} {
  set FMT_GRN "\033\[1;32m"
  set FMT_CLR "\033\[0;0m"

  set delay 0.1
  lappend spinner_chars "${FMT_GRN}/${FMT_CLR}"
  lappend spinner_chars "${FMT_GRN}-${FMT_CLR}"
  lappend spinner_chars "${FMT_GRN}\\${FMT_CLR}"
  lappend spinner_chars "${FMT_GRN}|${FMT_CLR}"
  set tot_frames [llength $spinner_chars]

  scr_init

  chan configure stdin -blocking 0 -buffering none
  chan configure stdout -blocking 0 -buffering none
  chan configure stderr -blocking 0 -buffering none

  for {set i 0} {1} {incr i} {
    set frame_idx [expr {$i % $tot_frames}]
    set fmtstr [format "\[%s\] %s\r" [lindex $spinner_chars $frame_idx] "$msg"]

    chan puts -nonewline "$fmtstr"
    chan flush stdout

    sleep $delay
    if {[chan gets stdin] eq "die"} {break}
  }

  scr_cleanup "$len" "$msg"
  return
}

run_spinner "$::SPINNER_LEN" "$::MSG"
exit 0
