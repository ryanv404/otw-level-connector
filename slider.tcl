#!/usr/bin/env expect

set SLIDER_LEN 5
set MSG "Connecting..."
set HAS_TPUT 0

trap {scr_cleanup $SLIDER_LEN $MSG; exit 0;} {INT QUIT}

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

proc run_slider {len msg} {
  set FMT_GRN "\033\[1;32m"
  set FMT_CLR "\033\[0;0m"

  set DELAY 0.1
  set PAD_CHAR "."
  set SLIDER_CHARS [list "${FMT_GRN}/${FMT_CLR}" "${FMT_GRN}\\${FMT_CLR}"]

  set chars_idx 0
  set slider_listlen [llength $SLIDER_CHARS]
  set slider_char [lindex $SLIDER_CHARS $chars_idx]
  set tot_frames [expr {$len * 2}]

  scr_init

  for {set i 0} {1} {incr i} {
    set frame [expr {$i % $tot_frames}]
    if {$frame == 0 && $i != 0} {
      incr chars_idx
      set chars_idx [expr {$chars_idx % $slider_listlen}]
      set slider_char [lindex $SLIDER_CHARS $chars_idx]
    } elseif {$frame == $len} {
      incr chars_idx
      set chars_idx [expr {$chars_idx % $slider_listlen}]
      set slider_char [lindex $SLIDER_CHARS $chars_idx]
    }

    if {$frame < $len} {
      set lhs [string repeat "$PAD_CHAR" $frame]
      set rhs [string repeat "$PAD_CHAR" [expr {$len - $frame}]]
    } else {
      set lhs [string repeat "$PAD_CHAR" [expr {$tot_frames - $frame}]]
      set rhs [string repeat "$PAD_CHAR" [expr {$frame - $len}]]
    }

    set fmtstr [format "\[%s%s%s\] %s\r" $lhs $slider_char $rhs $msg]
    puts -nonewline "$fmtstr"
    flush stdout

    sleep $DELAY
  }

  scr_cleanup $len $msg
  return
}

run_slider "$SLIDER_LEN" "$MSG"
exit 0
