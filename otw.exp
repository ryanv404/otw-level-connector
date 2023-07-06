#!/usr/bin/env expect
#########################################################
# BY:    ryanv404, 2023.                                #
# DESC:  Expect script that connects to OTW levels via  #
#        SSH and manages level passwords.               #
# USAGE: ./otw.exp LEVEL                                #
#########################################################

###[ USER CONFIGS ]######################################
set HOME_DIR          $::env(HOME)
set DATA_DIR          ".otw"
set DATA_FILENAME     "otw_data.txt"
set DEFAULT_DIRPATH   [file join $::HOME_DIR $::DATA_DIR]
set DEFAULT_FILEPATH  [file join $::DEFAULT_DIRPATH $::DATA_FILENAME]

###[ EXPECT CONFIGS ]####################################
log_user      0
exp_internal  0
set timeout   10
match_max     100000

###[ MAX LEVELS AND PORTS ]##############################
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

###[ PROCEDURES ]########################################
proc print_error_msg {msg} {
  puts stderr [format "\[-\] %s" $msg]
  return
}

proc exit_msg {msg} {
  puts stderr [format "\[-\] %s" $msg]
  exit -1
}

proc exit_usage {{msg {}}} {
  if {[string length $msg] != 0} {
    puts stderr [format "\[-\] %s" $msg]
  }
  puts stderr "usage:"
  puts stderr "  $::argv0 \[-h\] \[-p PASSWORD\] \[-l LEVEL\] LEVEL"
  exit -1
}

proc print_valid_levels {} {
  puts stderr "\[-\] Valid OTW levels are: bandit, natas, leviathan, krypton, narnia,"
  puts stderr "    behemoth, utumno, maze, vortex, manpage, drifter, and formulaone."
  return 0
}

proc handle_cmdline_opts {optslist levelarr} {
  upvar $levelarr LEVEL

  set removed_args ""

  while {[llength $optslist] > 0} {
    set current [lindex $optslist 0]

    # Stop option processing immediately if current arg is "--"
    if {[string equal $current "--"] == 1} {
      set optslist [lrange $optslist 1 end]
      break
    }

    # If not opt-like, then pop argument into the removed_args list and continue
    if {[string equal -length 1 $current "-"]  != 1 &&
        [string equal -length 2 $current "--"] != 1} {
      lappend removed_args $current
      set optslist [lrange $optslist 1 end]
      continue
    }

    set opt $current
    switch -exact -- $opt {
      {-l}         -
      {-p}         -
      {--level}    -
      {--password} {
        set optslist [lrange $optslist 1 end]
        set optarg [lindex $optslist 0]
        if {[string length $optarg] < 1} {
          exit_usage "Missing required argument for option \"$opt\"."
        }

        if {[string equal $opt "-l"] == 1}     {set opt "level"}  \
        elseif {[string equal $opt "-p"] == 1} {set opt "password"}
        set LEVEL($opt) $optarg
        set optslist [lrange $optslist 1 end]
        continue
      }
      {-?}      -
      {-h}      -
      {--help}  {
        exit_usage
      }
      default {
        exit_usage "Unknown option \"$current\"."
      }
    }
  }

  # If level was not set with -l, assign remaining non-option args to LEVEL(level)
  if {[string length $LEVEL(level)] == 0} {
    set LEVEL(level) [list {*}$optslist {*}$removed_args]
  }

  return 0
}

proc parse_level_arg {levelarr} {
  upvar $levelarr LEVEL

  set level_RE { *([[:alpha:]]+) *([[:digit:]]+) *}
  if {[regexp -nocase -- $level_RE $LEVEL(level) -> sub1 sub2] == 0} {return 1}

  # Ensure name is lowercase for validation checks
  set LEVEL(name) [string tolower $sub1]

  # Guard against leading zeroes that cause unintended octals
  if {[scan $sub2 %d LEVEL(num)] != 1} {return 1}
  return 0
}

proc validate_level_arg {levelarr} {
  upvar $levelarr LEVEL

  # Validate level name
  set name_is_valid 0
  foreach {key} [array names ::LEVELDATA] {
    if {[string equal $key $LEVEL(name)] == 1} {
      set name_is_valid 1
      set levelmax [lindex $::LEVELDATA($key) 1]
      break
    }
  }

  if {! $name_is_valid} {
    print_valid_levels
    return 1
  }

  # Validate level number
  if {$LEVEL(num) < 0 || $LEVEL(num) > $levelmax} {
    set min [format "%s0" $LEVEL(name)]
    set max [format "%s%d" $LEVEL(name) $levelmax]
    print_error_msg "Valid $LEVEL(name) level numbers are: $min - $max."
    return 1
  }

  set LEVEL(port) [lindex $::LEVELDATA($LEVEL(name)) 0]
  set LEVEL(host) [format "%s.labs.overthewire.org" $LEVEL(name)]
  return 0
}

proc get_saved_password {levelarr} {
  upvar $levelarr LEVEL

  set pass_str "?"

  # Create a password file if one does not exist
  if {! [file exists $::DEFAULT_FILEPATH]} {
    if {[create_password_file LEVEL] != 0} {return $pass_str}
  }

  if {[catch {open $::DEFAULT_FILEPATH r} pass_fd]} {
    print_error_msg "Unable to open the password file."
    return $pass_str
  }

  # Read file line-by-line until the current level's data is found
  set level_data_found 0
  while {[gets $pass_fd line] >= 0} {
    set lvlname [lindex [split $line " "] 0]
    if {[string equal $lvlname $LEVEL(level)] == 1} {
      set level_data_found 1
      set pass_str [lindex [split $line " "] 1]
      break
    }
  }

  if {! $level_data_found} {
    print_error_msg "Unable to find any saved data for level \"$LEVEL(level)\"."
  }

  close $pass_fd
  return "$pass_str"
}

proc create_password_file {levelarr} {
  upvar $levelarr LEVEL

  # If home directory cannot be used, then use current directory
  if {! [file exist $::HOME_DIR]       ||
      ! [file isdirectory $::HOME_DIR] ||
      ! [file writable $::HOME_DIR]}   {
    print_error_msg "Unable to create a file in the home directory to store OTW passwords."
    return 1
  }

  # Create data directory if it does not exist
  if {! [file exist $::DEFAULT_DIRPATH]} {
    if {[catch {file mkdir $::DEFAULT_DIRPATH} err_msg]} {
      print_error_msg "$err_msg"
      return 1
    }
  }

  # Bail out if a data file already exists and it contains data
  if {[file exist $::DEFAULT_FILEPATH] &&
      [file size $::DEFAULT_FILEPATH] != 0} {
    return 0
  }

  # Create and open the new password file for writing
  if {[catch {open $::DEFAULT_FILEPATH w} pass_fd]} {
    print_error_msg "Could not create a password file."
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
  puts stderr "\[+\] Created a password file at $::DEFAULT_FILEPATH"
  return 0
}

proc update_password_file {levelarr updated_pass} {
  upvar $levelarr LEVEL

  if {! [file exist $::DEFAULT_FILEPATH]}           {return 1}
  if {[catch {open $::DEFAULT_FILEPATH r} pass_fd]} {return 1}

  set temp_filepath [file join $::DEFAULT_DIRPATH "tempfile.txt"]
  if {[catch {open $temp_filepath w} temp_fd]} {return 1}

  # Update the current level's password field
  set pass_was_updated 0
  while {[gets $pass_fd line] >= 0} {
    set lvlname [lindex [split $line " "] 0]
    if {[string equal $lvlname $LEVEL(level)] == 1} {
      puts $temp_fd "${lvlname} ${updated_pass}"
      set pass_was_updated 1
    } else {
      puts $temp_fd "$line"
    }
  }

  close $pass_fd
  close $temp_fd

  # Replace old password file with the new file
  file rename -force -- $temp_filepath $::DEFAULT_FILEPATH

  if {! $pass_was_updated} {
    print_error_msg "Could not locate a \"$LEVEL(level)\" entry in the password file."
    return 1
  }

  return 0
}

proc handle_natas_levels {levelarr} {
  upvar $levelarr LEVEL

  puts "\[*\] Use a web browser to connect to natas levels:"
  puts "    Username: $LEVEL(level)"
  if {[string equal $LEVEL(password) "?"] != 1} {
    puts "    Password: $LEVEL(password)"
  }
  puts "    Website:  http://$LEVEL(level).natas.labs.overthewire.org"
  return 0
}

proc handle_newhost {levelarr spnid} {
  upvar $levelarr LEVEL

  exp_send -i $spnid -- "yes\r"
  send_user -- "\[*\] $LEVEL(host) was added as a known host.\n"
  return
}

proc handle_shell_prompt {levelarr spnid newpass} {
  upvar $levelarr LEVEL

  if {[string equal "?" "$newpass"] != 1} {
    if {[update_password_file LEVEL "$newpass"] != 0} {
      send_error -- "\[-\] Password could not be saved.\n"
    } else {
      send_user -- "\[+\] Password saved.\n"
    }
  }
  send_user -- "\[+\] Logged in as $LEVEL(level).\n"
  exp_send -i $spnid -- "\r"
  return
}

proc handle_pass_prompt {levelarr spnid newpass} {
  upvar $levelarr LEVEL
  upvar $newpass updated_pass

  if {[string equal "?" "$LEVEL(password)"] != 1} {
    exp_send -i $spnid -- "$LEVEL(password)\r"
  } else {
    send_user -- "\[*\] Enter the $LEVEL(level) password: "
    expect_user -re {^(.*)\n$}
    if {[info exist expect_out(1,string)]} {
      set updated_pass $expect_out(1,string)
    } else {
      send_error -- "\n\[-\] Unable to process user input.\n"
    }
    exp_send -i $spnid -- "$updated_pass\r"
  }
  return
}

proc handle_bad_pass {levelarr spnid newpass} {
  upvar $levelarr LEVEL
  upvar $newpass updated_pass

  send_user -- "\[-\] Incorrect password. Enter the $LEVEL(level) password: "
  expect_user -re {^(.*)\n$}
  if {[info exist expect_out(1,string)]} {
    set updated_pass $expect_out(1,string)
  } else {
    send_error -- "\n\[-\] Unable to process user input.\n"
  }
  exp_send -i $spnid -- "$updated_pass\r"
  return
}

proc handle_timeout {} {
  send_error -- "\n\[-\] The connection timed out.\n"
  return
}

proc handle_eof {buf} {
  set too_many_attempts_RE {Permission denied \(publickey\,password\)\.}
  if {[regexp $too_many_attempts_RE $buf)] == 1} {
    send_error -- "\[-\] Max number of attempts exceeded.\n"
  }
  return
}

proc connect_to_level {levelarr} {
  upvar $levelarr LEVEL

  set updated_pass "?"
  set prompt "(%|>|:|\#|\\$) $"

  if {[string length [auto_execok "ssh"]] == 0} {
    print_error_msg "Could not find \`ssh\` command on your system's executable path."
    return 1
  }

  spawn ssh -p $LEVEL(port) "$LEVEL(level)\@$LEVEL(host)"
  send_user -- "\[*\] Connecting to $LEVEL(host) as $LEVEL(level)...\n"

  expect {
    -timeout 2 -re {yes/no.*$} {handle_newhost LEVEL $spawn_id}
  }

  expect {
    -re {denied.*assword: $} \
                     {handle_bad_pass LEVEL $spawn_id updated_pass; exp_continue}
    -re {assword: $} {handle_pass_prompt LEVEL $spawn_id updated_pass; exp_continue}
    -re $prompt      {handle_shell_prompt LEVEL $spawn_id "$updated_pass"}
    timeout          {handle_timeout; return 1}
    eof              {handle_eof "${expect_out(buffer)}"; return 1}
  }

  interact
  return 0
}

###[ MAIN FUNCTION ]#####################################
proc run_program {argslist} {
  set LEVEL(num)        -1
  set LEVEL(name)       ""
  set LEVEL(host)       ""
  set LEVEL(port)       ""
  set LEVEL(level)      ""
  set LEVEL(password)   "?"

  if {[handle_cmdline_opts $argslist LEVEL] != 0} {return 1}
  if {[parse_level_arg LEVEL] != 0}               {return 1}
  if {[validate_level_arg LEVEL] != 0}            {return 1}

  # Update password file if a password was provided on the commandline
  if {[string equal "?" "$LEVEL(password)"] != 1} {
    if {[update_password_file LEVEL "$LEVEL(password)"] != 0} {
      print_error_msg "Password could not be saved."
      exit -1
    } else {
      puts stderr "\[+\] Password saved."
      exit 0
    }
  }

  # Returns "?" if there are any errors to allow user to input password later
  set LEVEL(password) [get_saved_password LEVEL]

  if {[string equal "natas" $LEVEL(name)] == 1} {
    handle_natas_levels LEVEL
    return 0
  }

  if {[connect_to_level LEVEL] != 0} {return 1}
  return 0
}

###[ RUN PROGRAM ]#######################################
if {$::argc < 1}                  {exit_usage}
if {[run_program $::argv] != 0}   {exit -1}
exit 0
