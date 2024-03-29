#!/usr/bin/env expect
#####################################################################
# BY:    ryanv404, 2023.                                            #
# DESC:  Expect script that connects to OTW levels via SSH and      #
#        manages level passwords.                                   #
# USAGE: ./otw.exp [-h] [-p PASSWORD] [-l] LEVEL                    #
#####################################################################

###[ GLOBAL CONFIGS ]##################################################
set HOME_DIR          "$::env(HOME)"
set DEFAULT_DIR       [file join "$::HOME_DIR" ".otw"]
set DEFAULT_FILEPATH  [file join "$::DEFAULT_DIR" "otw_data.txt"]
set SCRIPT_NAME       "$::argv0"
set SCRIPT            [file normalize "$::argv0"]
set SCRIPT_DIR        [file dirname [file normalize "$::argv0"]]
set SSH_CMD           [auto_execok "ssh"]
set TPUT_CMD          [auto_execok "tput"]
set HAS_SSH           [expr {[string length "$::SSH_CMD"]  == 0 ? 0 : 1}]
set HAS_TPUT          [expr {[string length "$::TPUT_CMD"] == 0 ? 0 : 1}]

if {$::HAS_TPUT} {
  set FMT_RED  "\033\[1;31m"
  set FMT_GRN  "\033\[1;32m"
  set FMT_CYAN "\033\[1;36m"
  set FMT_CLR  "\033\[0;0m"
} else {
  set FMT_RED  ""
  set FMT_GRN  ""
  set FMT_CYAN ""
  set FMT_CLR  ""
}

###[ EXPECT CONFIGS ]################################################
log_user      0
exp_internal  0
match_max     100000

###[ LEVELS DATA ]###################################################
array set LEVELDATA {
  {natas}         {0 34}
  {maze}        {2225 9}
  {narnia}      {2226 9}
  {utumno}      {2227 8}
  {krypton}     {2231 7}
  {manpage}     {2224 7}
  {behemoth}    {2221 8}
  {leviathan}   {2223 7}
  {formulaone}  {2232 6}
  {bandit}     {2220 34}
  {vortex}     {2228 27}
  {drifter}    {2230 15}
}

###[ UTILITY PROCS ]##################################################
proc pstderr {msg} {
  puts stderr "$msg"
  return
}

proc print_error {msg} {
  pstderr [format "\[${::FMT_RED}-${::FMT_CLR}\] %s" "$msg"]
  return
}

proc print_success {msg} {
  pstderr [format "\[${::FMT_GRN}+${::FMT_CLR}\] %s" "$msg"]
  return
}

proc print_info {msg} {
  pstderr [format "\[${::FMT_CYAN}*${::FMT_CLR}\] %s" "$msg"]
  return
}

proc exit_msg {msg} {
  print_error "$msg"
  exit -1
}

proc exit_usage {{msg {}}} {
  if {[string length $msg] != 0} {
    print_error [format "%s\n" "$msg"]
  }
  pstderr "usage:"
  pstderr "  $::SCRIPT_NAME \[-h\] \[-p PASSWORD\] \[-l\] LEVEL"
  exit -1
}

proc print_valid_levels {} {
  print_error "Valid OTW levels are: bandit, natas, leviathan, krypton, narnia,"
  pstderr "    behemoth, utumno, maze, vortex, manpage, drifter, and formulaone."
  return 0
}

proc handle_natas_levels {levelarr} {
  upvar $levelarr LEVEL

  print_info "Use a web browser to connect to natas levels:"
  pstderr "    Username: $LEVEL(level)"
  if {[string equal "$LEVEL(password)" "?"] != 1} {
    pstderr "    Password: $LEVEL(password)"
  }
  pstderr "    Website:  http://$LEVEL(level).natas.labs.overthewire.org"
  return 0
}

###[ CMDLINE OPTION PARSING PROC ]###################################
proc handle_cmdline_opts {optslist levelarr} {
  upvar $levelarr LEVEL

  set removed_args ""

  while {[llength "$optslist"] > 0} {
    set current [lindex "$optslist" 0]

    # Stop option processing immediately if current arg is "--"
    if {[string equal "$current" "--"] == 1} {
      set optslist [lrange "$optslist" 1 end]
      break
    }

    # If not opt-like, then pop argument into the removed_args list and continue
    if {[string equal -length 1 "$current" "-"]  != 1 &&
        [string equal -length 2 "$current" "--"] != 1} {
      lappend removed_args "$current"
      set optslist [lrange "$optslist" 1 end]
      continue
    }

    set opt "$current"
    switch -exact -- "$opt" {
      {-l}         -
      {-p}         -
      {--level}    -
      {--password} {
        set optslist [lrange "$optslist" 1 end]
        set optarg   [lindex "$optslist" 0]
        if {[string length "$optarg"] < 1} {
          exit_usage "Missing required argument for option \"$opt\""
        }

        if {[string equal "$opt" "-l"]     == 1} {set opt "level"}  \
        elseif {[string equal "$opt" "-p"] == 1} {set opt "password"}
        set LEVEL($opt) "$optarg"
        set optslist    [lrange "$optslist" 1 end]
        continue
      }
      {--__spinner1} -
      {--__spinner2} {
        set choice [string range "$opt" end end]
        set loading_msg [format "Connecting to %s..." [lindex $optslist 1]]

        if {$choice == 1} {
          set slider_len 5
          run_slider "$slider_len" "$loading_msg"
        } else {
          set spinner_len 3
          run_spinner "$spinner_len" "$loading_msg"
        }
        exit 0
      }
      {-?}      -
      {-h}      -
      {--help}  {exit_usage}
      default   {exit_usage "Unknown option \"$current\""}
    }
  }

  # If level was not set with -l, assign remaining non-option args to LEVEL(level)
  if {[string length "$LEVEL(level)"] == 0} {
    set LEVEL(level) [list {*}$optslist {*}$removed_args]
  }

  return 0
}

###[ LOADING SPINNER PROCS ]#########################################
proc scr_init {} {
  if {$::HAS_TPUT} {
    # Executes in child subprocess, so redirect to current stdout 
    exec "$::TPUT_CMD" civis >@stdout
  }
  return
}

proc scr_cleanup {len msg} {
  set strlen [string length "$msg"]
  set maxlen [expr {$len + $strlen + 12}]

  chan puts -nonewline [format "\r%s\r" [string repeat " " $maxlen]]

  # Executes in child subprocess, so redirect to current stdout 
  if {$::HAS_TPUT} {exec "$::TPUT_CMD" cnorm >@stdout}
  return
}

proc run_slider {len msg} {
  set delay   0.1
  set padchar "."

  lappend slider_chars "${::FMT_GRN}/${::FMT_CLR}"
  lappend slider_chars "${::FMT_GRN}\\${::FMT_CLR}"

  set chars_idx      0
  set slider_char    [lindex "$slider_chars" $chars_idx]
  set tot_frames     [expr {$len * 2}]
  set slider_listlen [llength "$slider_chars"]

  chan configure stdin  -blocking 0 -buffering none
  chan configure stdout -blocking 0 -buffering none
  chan configure stderr -blocking 0 -buffering none

  scr_init

  for {set i 0} {1} {incr i} {
    set frame [expr {$i % $tot_frames}]
    if {$frame == 0 && $i != 0} {
      incr chars_idx
      set  chars_idx   [expr {$chars_idx % $slider_listlen}]
      set  slider_char [lindex "$slider_chars" $chars_idx]
    } elseif {$frame == $len} {
      incr chars_idx
      set  chars_idx   [expr {$chars_idx % $slider_listlen}]
      set  slider_char [lindex "$slider_chars" $chars_idx]
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
    sleep $delay
    if {[string equal "die" [chan gets stdin]]} {break}
  }

  scr_cleanup "$len" "$msg"
  return
}

proc run_spinner {len msg} {
  set delay 0.1

  lappend spinner_chars "${::FMT_CYAN}/${::FMT_CLR}"
  lappend spinner_chars "${::FMT_CYAN}-${::FMT_CLR}"
  lappend spinner_chars "${::FMT_CYAN}\\${::FMT_CLR}"
  lappend spinner_chars "${::FMT_CYAN}|${::FMT_CLR}"

  set tot_frames [llength "$spinner_chars"]

  chan configure stdin  -blocking 0 -buffering none
  chan configure stdout -blocking 0 -buffering none
  chan configure stderr -blocking 0 -buffering none

  scr_init

  for {set i 0} {1} {incr i} {
    set frame_idx [expr {$i % $tot_frames}]
    set fmtstr    [format "\[%s\] %s\r" [lindex "$spinner_chars" $frame_idx] "$msg"]
    chan puts -nonewline "$fmtstr"
    sleep $delay
    if {[string equal "die" [chan gets stdin]]} {break}
  }

  scr_cleanup "$len" "$msg"
  return
}

proc start_spinner {levelarr} {
  upvar $levelarr LEVEL

  lappend script_args [info nameofexecutable]
  lappend script_args "$::SCRIPT"

  # I like the slider more so this makes it 3x more common :-)
  if {[expr {int(rand() * 4)}] >= 1} {
    lappend script_args "--__spinner1"
  } else {
    lappend script_args "--__spinner2"
  }

  lappend script_args "$LEVEL(host)"

  # Redirect subprocess' outputs to parent's stderr
  lappend script_args ">&@stderr"

  # Create a pipeline to asynchronously run a loading spinner
  set rv [catch {open |[list {*}$script_args] "w"} chan]
  if {$rv > 0} {return ""}

  # Make pipeline unbuffered and non-blocking from parent's side
  chan configure $chan  -blocking 0 -buffering none
  chan configure stdout -blocking 0 -buffering none
  chan configure stderr -blocking 0 -buffering none
  return "$chan"
}

proc kill_spinner {spinner_id} {
  if {$spinner_id in [chan names]} {
    chan configure $spinner_id -blocking 1
    chan puts $spinner_id "die"
    chan flush $spinner_id
    catch {chan close $spinner_id}

    # Restore settings
    chan configure stdout -blocking 1 -buffering line
    chan configure stderr -blocking 1 -buffering none
  }
  return
}

###[ INPUT VALIDATION PROCS ]########################################
proc parse_level_arg {levelarr} {
  upvar $levelarr LEVEL

  set level_RE { *([[:alpha:]]+) *([[:digit:]]+) *}
  if {[regexp -nocase -- "$level_RE" "$LEVEL(level)" -> sub1 sub2] == 0} {return 1}

  # Ensure name is lowercase for validation checks
  set LEVEL(name) [string tolower "$sub1"]

  # Guard against leading zeroes that cause unintended octals
  if {[scan "$sub2" "%d" LEVEL(num)] != 1} {return 1}
  return 0
}

proc validate_level_arg {levelarr} {
  upvar $levelarr LEVEL

  # Validate level name
  set name_is_valid 0
  foreach {lname} [array names ::LEVELDATA] {
    if {[string equal "$lname" "$LEVEL(name)"] == 1} {
      set name_is_valid 1
      set levelmax [lindex "$::LEVELDATA($lname)" 1]
      break
    }
  }

  if {! $name_is_valid} {
    print_valid_levels
    return 1
  }

  # Validate level number
  if {$LEVEL(num) < 0 || $LEVEL(num) > $levelmax} {
    set min [format "%s0" "$LEVEL(name)"]
    set max [format "%s%d" "$LEVEL(name)" $levelmax]
    print_error "Valid $LEVEL(name) level numbers are: $min - $max."
    return 1
  }

  set LEVEL(port) [lindex "$::LEVELDATA($LEVEL(name))" 0]
  set LEVEL(host) [format "%s.labs.overthewire.org" "$LEVEL(name)"]
  return 0
}

###[ LOCAL DATA I/O PROCS ]##########################################
proc get_saved_password {levelarr} {
  upvar $levelarr LEVEL

  set pass_str "?"

  # Create a password file if one does not exist
  if {[file exists "$::DEFAULT_FILEPATH"] == 0 &&
      [create_password_file LEVEL]        != 0} {
    return "$pass_str"
  }

  if {[catch {open "$::DEFAULT_FILEPATH" r} pass_fd]} {
    print_error "Unable to open the password file."
    return "$pass_str"
  }

  # Read file line-by-line until the current level's data is found
  set level_data_found 0
  while {[gets $pass_fd line] >= 0} {
    set splitline [split "$line" " "]
    set lvlname   [lindex "$splitline" 0]

    if {[string equal "$lvlname" "$LEVEL(level)"] == 1} {
      set pass_str [lindex "$splitline" 1]
      set level_data_found 1
      break
    }
  }

  if {! $level_data_found} {
    print_error "Unable to find any saved data for level \"$LEVEL(level)\"."
  }

  close $pass_fd
  return "$pass_str"
}

proc create_password_file {levelarr} {
  upvar $levelarr LEVEL

  if {[file exists "$::HOME_DIR"]      == 0 ||
      [file isdirectory "$::HOME_DIR"] == 0 ||
      [file writable "$::HOME_DIR"]    == 0} {
    print_error "Unable to create a file in the home directory to store OTW passwords."
    return 1
  }

  # Create data directory if it does not exist
  if {[file exists "$::DEFAULT_DIR"]                == 0 &&
      [catch {file mkdir "$::DEFAULT_DIR"} err_msg] != 0} {
    print_error "$err_msg"
    return 1
  }

  # Bail out if a data file already exists and it contains data
  if {[file exists "$::DEFAULT_FILEPATH"] != 0 &&
      [file size "$::DEFAULT_FILEPATH"]   != 0} {
    return 0
  }

  # Create and open the new password file for writing
  if {[catch {open "$::DEFAULT_FILEPATH" w} pass_fd]} {
    print_error "Could not create a password file."
    return 1
  }

  # Write default data into the file
  foreach name [array names ::LEVELDATA] {
    set maxlevel [lindex $::LEVELDATA($name) 1]
    for {set i 0} {$i <= $maxlevel} {incr i} {
      switch -exact -- "${name}${i}" {
        {maze0}      -
        {natas0}     -
        {bandit0}    -
        {narnia0}    -
        {utumno0}    -
        {manpage0}   -
        {behemoth0}  -
        {leviathan0} {puts $pass_fd "${name}${i} ${name}${i}"}
        default      {puts $pass_fd "${name}${i} ?"}
      }
    }
  }

  close $pass_fd
  print_success "Created a password file at: $::DEFAULT_FILEPATH"
  return 0
}

proc update_password_file {levelarr newpass} {
  upvar $levelarr LEVEL

  if {! [file exists "$::DEFAULT_FILEPATH"]}          {return 1}
  if {[catch {open "$::DEFAULT_FILEPATH" r} pass_fd]} {return 1}

  set temp_filepath [file join "$::DEFAULT_DIR" "tempfile.txt"]
  if {[catch {open "$temp_filepath" w} temp_fd]}      {return 1}

  # Update the current level's password field
  set pass_was_updated 0
  while {[gets $pass_fd line] >= 0} {
    set lvlname [lindex [split "$line" " "] 0]

    if {! $pass_was_updated &&
        [string equal "$lvlname" "$LEVEL(level)"] == 1} {
      puts $temp_fd "$lvlname $newpass"
      set pass_was_updated 1
    } else {
      puts $temp_fd "$line"
    }
  }

  close $pass_fd
  close $temp_fd

  # Replace old password file with the new file
  file rename -force -- "$temp_filepath" "$::DEFAULT_FILEPATH"

  if {! $pass_was_updated} {return 1} \
  else {return 0}
}

###[ EXPECT SSH CONNECTION PROCS ]###################################
proc handle_new_host {levelarr ssh_id} {
  upvar $levelarr LEVEL

  exp_send -i "$ssh_id" -- "yes\r"
  return
}

proc handle_shell_prompt {levelarr ssh_id new_pass spinner_id} {
  upvar $levelarr LEVEL

  kill_spinner $spinner_id

  if {[string equal "?" "$new_pass"] != 1} {
    if {[update_password_file LEVEL "$new_pass"] != 0} {
      set msg "Password could not be saved."
      send_error -- [format "\[${::FMT_RED}-${::FMT_CLR}\] %s\n" "$msg"]
    } else {
      set msg "Password saved."
      send_user -- [format "\[${::FMT_GRN}+${::FMT_CLR}\] %s\n" "$msg"]
    }
  }

  exp_send -i "$ssh_id" -- "\r"
  return
}

proc handle_pass_prompt {levelarr ssh_id newpass attemptcode spinner_id} {
  upvar $levelarr LEVEL
  upvar $newpass new_pass
  upvar $attemptcode attempt_code

  switch -exact -- $attempt_code {
    {1} {
      if {[string equal "?" "$LEVEL(password)"] != 1} {
        exp_send -i "$ssh_id" -- "$LEVEL(password)\r"
        set attempt_code 2
        return
      } else {
        kill_spinner $spinner_id

        set msg "Enter the $LEVEL(level) password: "
        send_user -- [format "\[${::FMT_CYAN}*${::FMT_CLR}\] %s" "$msg"]
        expect_user -re {^(.*)\n$}

        if {[info exists expect_out(1,string)]} {
          set new_pass "$expect_out(1,string)"
        } else {
          set msg "Unable to process user input."
          send_error -- [format "\n\[${::FMT_RED}-${::FMT_CLR}\] %s\n" "$msg"]
        }

        exp_send -i "$ssh_id" -- "$new_pass\r"
        set attempt_code 3
      }
    }
    {2} {
      kill_spinner $spinner_id

      set msg "Enter the $LEVEL(level) password: "
      send_user -- [format "\[${::FMT_CYAN}*${::FMT_CLR}\] %s" "$msg"]
      expect_user -re {^(.*)\n$}

      if {[info exists expect_out(1,string)]} {
        set new_pass "$expect_out(1,string)"
      } else {
        set msg "Unable to process user input."
        send_error -- [format "\n\[${::FMT_RED}-${::FMT_CLR}\] %s\n" "$msg"]
      }

      exp_send -i "$ssh_id" -- "$new_pass\r"
      set attempt_code 3
    }
    {3} {
      set msg "Incorrect password. Enter the $LEVEL(level) password: "
      send_user -- [format "\[${::FMT_RED}-${::FMT_CLR}\] %s" "$msg"]
      expect_user -re {^(.*)\n$}

      if {[info exists expect_out(1,string)]} {
        set new_pass "$expect_out(1,string)"
      } else {
        set msg "Unable to process user input."
        send_error -- [format "\n\[${::FMT_RED}-${::FMT_CLR}\] %s\n" "$msg"]
      }

      exp_send -i "$ssh_id" -- "$new_pass\r"
      set attempt_code 4

      # Reset saved password to default "?" value if it was incorrect
      if {[string equal "?" "$LEVEL(password)"] != 1} {
        update_password_file LEVEL "?"
      }
    }
    {4} {
      set msg "Incorrect password. Enter the $LEVEL(level) password: "
      send_user -- [format "\[${::FMT_RED}-${::FMT_CLR}\] %s" "$msg"]
      expect_user -re {^(.*)\n$}

      if {[info exists expect_out(1,string)]} {
        set new_pass "$expect_out(1,string)"
      } else {
        set msg "Unable to process user input."
        send_error -- [format "\n\[${::FMT_RED}-${::FMT_CLR}\] %s\n" "$msg"]
      }

      exp_send -i "$ssh_id" -- "$new_pass\r"

      # Reset saved password to default "?" value if it was incorrect
      if {[string equal "?" "$LEVEL(password)"] != 1} {
        update_password_file LEVEL "?"
      }
    }
    default {
      kill_spinner $spinner_id
      print_error "Error while processing user's password."
      cleanup_spawned_process "$ssh_id"
      exit -1
    }
  }

  return
}

proc handle_timeout {levelarr ssh_id spinner_id} {
  upvar $levelarr LEVEL

  kill_spinner $spinner_id

  set msg "Connection to $LEVEL(host) timed out."
  send_error -- [format "\[${::FMT_RED}-${::FMT_CLR}\] %s\n" "$msg"]
  cleanup_spawned_process "$ssh_id"
  return
}

proc too_many_attempts_check {ssh_id buf spinner_id} {
  set too_many_attempts_RE {Permission denied \(publickey\,password\)\.}

  kill_spinner $spinner_id

  if {[regexp "$too_many_attempts_RE" "$buf"] == 1} {
    set msg "Max number of login attempts exceeded."
    send_error -- [format "\[${::FMT_RED}-${::FMT_CLR}\] %s\n" "$msg"]
  }

  cleanup_spawned_process "$ssh_id"
  return
}

proc cleanup_spawned_process {ssh_id} {
  if {[catch {exp_close -i "$ssh_id"} errmsg] != 0 &&
      [regexp -- "not open" "$errmsg"]        == 0} {
    print_error "Error while closing the ssh channel.\n$errmsg"
  }

  set wres [exp_wait -i "$ssh_id"]
  if {[info exists wres]  == 1 &&
      [llength "$wres"]   == 4 &&
      [lindex "$wres" 2]  == -1} {
    print_error "An OS error (errno [lindex $wres 3]) occured in the ssh process."
  }

  return
}

proc connect_to_level {levelarr} {
  upvar $levelarr LEVEL

  set new_pass     "?"
  set prompt_RE    "(\#|\\$) $"
  set attempt_code 1

  if {"$::HAS_SSH" == 0} {
    print_error "Could not find \`ssh\` command on your system's executable path."
    return 1
  }

  set spinner [start_spinner LEVEL]

  set rv [spawn "$::SSH_CMD" -p $LEVEL(port) "$LEVEL(level)\@$LEVEL(host)"]
  if {$rv == 0} {
    kill_spinner "$spinner"
    print_error "Unable to spawn an ssh process."
    return 1
  }

  set ssh_id "$spawn_id"

  set timeout 10
  expect {
    -re {yes/no.*$}  {handle_new_host LEVEL "$ssh_id"
                      exp_continue}
    -re {assword: $} {handle_pass_prompt LEVEL "$ssh_id" new_pass attempt_code "$spinner"
                      exp_continue}
    timeout          {handle_timeout LEVEL "$ssh_id" "$spinner"
                      return 1}
    eof              {too_many_attempts_check "$ssh_id" "$expect_out(buffer)" "$spinner"
                      return 1}
    -re "$prompt_RE" {handle_shell_prompt LEVEL "$ssh_id" "$new_pass" "$spinner"}
  }

  # Disable local buffering and blocking to try to reduce keystroke delay
  chan configure stderr -blocking 0
  chan configure stdout -blocking 0 -buffering none
  chan configure stdin  -blocking 0 -buffering none

  interact
  cleanup_spawned_process "$ssh_id"
  return 0
}

###[ MAIN PROC ]#####################################################
proc run_program {argslist} {
  set LEVEL(num)         -1
  set LEVEL(name)        ""
  set LEVEL(host)        ""
  set LEVEL(port)        ""
  set LEVEL(level)       ""
  set LEVEL(password)   "?"

  if {[handle_cmdline_opts "$argslist" LEVEL] != 0} {return 1}
  if {[parse_level_arg LEVEL] != 0}                 {return 1}
  if {[validate_level_arg LEVEL] != 0}              {return 1}

  # Update password file if a password was provided on the commandline
  if {[string equal "?" "$LEVEL(password)"] != 1} {
    if {[update_password_file LEVEL "$LEVEL(password)"] != 0} {
      print_error "Password could not be saved."
      return 1
    } else {
      print_success "Password saved."
      return 0
    }
  }

  # Returns "?" if there are any errors so user can input a password later
  set LEVEL(password) [get_saved_password LEVEL]

  if {[string equal "natas" "$LEVEL(name)"] == 1} {
    handle_natas_levels LEVEL
  } else {
    if {[connect_to_level LEVEL] != 0} {return 1}
  }

  return 0
}

###[ RUN PROGRAM ]###################################################
if {$::argc < 1}                    {exit_usage}
if {[run_program "$::argv"] != 0}   {exit -1}
exit 0
