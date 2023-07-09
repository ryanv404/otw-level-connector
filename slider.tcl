#!/usr/bin/env expect

set SLIDER_LEN 5
set MSG [lindex $::argv 0]
set HAS_TPUT 0
set TPUT_CMD [auto_execok "tput"]

trap {scr_cleanup "$::SLIDER_LEN" "$::MSG"; exit 0;} {INT QUIT}

if {[string length "$::TPUT_CMD"] != 0} {
  set HAS_TPUT 1
}

proc scr_init {} {
  if {$::HAS_TPUT} {
    exec "$::TPUT_CMD" civis >@stdout
  } else {
    puts "ASCII hide cursor sequence"
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
    puts "ASCII unhide cursor sequence"
  }

  return
}

proc run_slider {len msg} {
  set FMT_GRN "\033\[1;32m"
  set FMT_CLR "\033\[0;0m"

  set delay 0.1
  set padchar "."
  lappend slider_chars "${FMT_GRN}/${FMT_CLR}"
  lappend slider_chars "${FMT_GRN}\\${FMT_CLR}"

  set chars_idx 0
  set slider_listlen [llength $slider_chars]
  set slider_char [lindex $slider_chars $chars_idx]
  set tot_frames [expr {$len * 2}]

  scr_init

  chan configure stdin -blocking 0 -buffering none
  chan configure stdout -blocking 0 -buffering none
  chan configure stderr -blocking 0 -buffering none

  for {set i 0} {1} {incr i} {
    set frame [expr {$i % $tot_frames}]
    if {$frame == 0 && $i != 0} {
      incr chars_idx
      set chars_idx [expr {$chars_idx % $slider_listlen}]
      set slider_char [lindex $slider_chars $chars_idx]
    } elseif {$frame == $len} {
      incr chars_idx
      set chars_idx [expr {$chars_idx % $slider_listlen}]
      set slider_char [lindex $slider_chars $chars_idx]
    }

    if {$frame < $len} {
      set lhs [string repeat "$padchar" $frame]
      set rhs [string repeat "$padchar" [expr {$len - $frame}]]
    } else {
      set lhs [string repeat "$padchar" [expr {$tot_frames - $frame}]]
      set rhs [string repeat "$padchar" [expr {$frame - $len}]]
    }

    set fmtstr [format "\[%s%s%s\] %s\r" "$lhs" "$slider_char" "$rhs" "$msg"]
    chan puts -nonewline "$fmtstr"
    chan flush stdout

    sleep $delay
    if {[chan gets stdin] eq "die"} {break}
  }

  scr_cleanup $len "$msg"
  return
}

run_slider "$::SLIDER_LEN" "$::MSG"
exit 0
