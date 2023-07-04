#!/usr/bin/env expect
#########################################################
# BY:    ryanv404, 2023.                                #
# DESC:  Expect script that connects to OTW levels via  #
#        SSH and manages level passwords.               #
# USAGE: ./otw.exp <LEVEL>                              #
#########################################################

###[ CONFIGS ]###########################################
log_user 0
set timeout 10
match_max 10000

###[ LEVELS DATA ]#######################################
array set LEVELS_DATA [list {maze}       {2225 9}    \
                            {natas}      {0000 34}   \
                            {utumno}     {2227 8}    \
                            {narnia}     {2226 9}    \
                            {vortex}     {2228 27}   \
                            {bandit}     {2220 34}   \
                            {krypton}    {2231 7}    \
                            {manpage}    {2224 7}    \
                            {drifter}    {2230 15}   \
                            {behemoth}   {2221 8}    \
                            {leviathan}  {2223 7}    \
                            {formulaone} {2232 6}]

###[ PROCEDURES ]########################################
proc show_usage { progname } {
  puts "usage: $progname <LEVEL>"
  puts "       $progname \[-p|--password <PASSWORD>] \[-l|--level <LEVEL>]"
  exit 1
}



proc parse_level { level lname lnum } {
  upvar $lname levelname
  upvar $lnum levelnum

  set lregex { *([[:alpha:]]+) *([[:digit:]]+) *}
  if {[regexp $lregex $level -> sub1 sub2]} {
    set levelname [string tolower $sub1]
	  # Strips leading zeroes that can cause unintended octal interpretation
    scan $sub2 %d levelnum
    return 0
  }

  puts "\[-] Valid OTW levels are: bandit, natas, leviathan, krypton, narnia,"
  puts "    behemoth, utumno, maze, vortex, manpage, drifter, and formulaone."
  exit 1
}

proc validate_level { lname lnum rhost rport } {
  upvar $rhost remotehost
  upvar $rport remoteport

  # Validate level name
  set check_passed 0
  foreach name [array names ::LEVELS_DATA] {
    if { "$lname" eq "$name" } {
      set check_passed 1
      set lmax [lindex [split "$::LEVELS_DATA($lname)" " "] 1]

      # Validate level number
      if { $lnum < 0 || $lnum > $lmax } {
        set zero 0
        puts "\[-] Valid $lname levels are: $lname$zero - $lname$lmax."
        exit 1
      }

      set remoteport [lindex [split "$::LEVELS_DATA($lname)" " "] 0]
      set remotehost "$lname.labs.overthewire.org"
      break
    }
  }

  if { ! $check_passed } {
    puts "\[-] Valid OTW levels are: bandit, natas, leviathan, krypton, narnia,"
    puts "    behemoth, utumno, maze, vortex, manpage, drifter, and formulaone."
    exit 1
  }

  return 0
}

proc get_saved_password { lname } {
  set pass_fpath "$::env(HOME)/.otw/otw_passwords.txt"
  set lpass "?"

  if { [catch {open "$pass_fpath" r} pass_fd] } {
    puts "\[-] Error opening password file."
    return "?"
  }

  while { [gets $pass_fd line] >= 0 } {
    set name [lindex [split $line " "] 0]
    if { "$lname" eq "$name" } {
      set lpass [lindex [split $line " "] 1]
      break
    }
  }

  close $pass_fd
  return "$lpass"
}

proc get_level_password { lname lpass } {
  upvar $lpass levelpass
  set pass_fpath "$::env(HOME)/.otw/otw_passwords.txt"
  set levelpass "?"

  if { [file exists "$pass_fpath"] } {
    set levelpass [get_saved_password "$lname"]
  } else {
    # No password file found, so create one
    set rv [create_password_file]
    if { $rv != 0 } {
      puts "\[-] Unable to create an OTW passwords file."
      return 1
    } else {
      set levelpass [get_saved_password "$lname"]
    }
  }

  return 0
}

proc create_password_file {} {
  set pass_fpath "$::env(HOME)/.otw/otw_passwords.txt"

  if { ! [file exists "$::env(HOME)/.otw"] || ! [file isdirectory "$::env(HOME)/.otw"] } {
    if { [file isdirectory "$::env(HOME)"] } {
      file mkdir "$::env(HOME)/.otw"
    } else {
      return 1
    }
  }

  if { [catch {open "$pass_fpath" w} pass_fd] } {
    puts "\[-] Error opening password file."
    return 1
  }

  # Write default data into file if it exists and has a size of 0 bytes
  puts "\[+] Created a password file at $pass_fpath"
  if { ! [file exists "$pass_fpath"] || [file size "$pass_fpath"] != 0 } {
    close $pass_fd
    return 1
  }

  foreach name [array names ::LEVELS_DATA] {
    set lmax [lindex [split "$::LEVELS_DATA($name)" " "] 1]
    for { set i 0 } { $i <= $lmax } { incr i } {
      switch -exact -- "$name$i" {
        "maze0" {puts $pass_fd "$name$i maze0"}
        "natas0" {puts $pass_fd "$name$i natas0"}
        "bandit0" {puts $pass_fd "$name$i bandit0"}
        "narnia0" {puts $pass_fd "$name$i narnia0"}
        "utumno0" {puts $pass_fd "$name$i utumno0"}
        "manpage0" {puts $pass_fd "$name$i manpage0"}
        "behemoth0" {puts $pass_fd "$name$i behemoth0"}
        "leviathan0" {puts $pass_fd "$name$i leviathan0"}
        default {puts $pass_fd "$name$i ?"}
      }
    }
  }
  close $pass_fd
  return 0
}

proc update_password_file { lname updated_pass } {
  set temp_fpath "$::env(HOME)/.otw/temp_file.txt"
  set pass_fpath "$::env(HOME)/.otw/otw_passwords.txt"

  if { ! [file exists "$pass_fpath"] } {
    return 1
  }

  if { [catch {open "$pass_fpath" r} pass_fd] } {
    puts "\[-] Error opening password file."
    return 1
  }

  if { [catch {open "$temp_fpath" w} temp_fd] } {
    puts "\[-] Error opening temporary file."
    return 1
  }

  # Update the current level's password field
  while { [gets $pass_fd line] >= 0 } {
    set name [lindex [split $line " "] 0]
    if { "$lname" eq "$name" } {
      puts $temp_fd "$name:$updated_pass"
    } else {
      puts $temp_fd "$line"
    }
  }

  # Replace old password file with the new file
  file rename -force -- "$temp_fpath" "$pass_fpath"

  close $pass_fd
  close $temp_fd
  return 0
}

proc handle_natas_levels { level lpass } {
  puts "\[*] Use a web browser to connect to natas levels:"
  puts "    Username: $level"
  if { "$lpass" ne "?" } {
    puts "    Password: $lpass"
  }
  puts "    Website:  http://$level.natas.labs.overthewire.org"
  return 0
}

proc connect_to_level { rhost rport level lpass } {
  set updated_pass "?"

  set SSH_CMD [auto_execok "sshs"]
  if {[string length $SSH_CMD] == 0} {
    puts "\[-] Could not find \`ssh\` command on your system's executable path."
    return 1
  }

  send_user -- "\[*] Connecting to $rhost as $level...\n"
  spawn $SSH_CMD -p $rport "$level\@$rhost"

  expect {
    # Handle first connect to server
    -re {yes/no.* $} {
      send -- "yes\r"
      exp_continue
    } -re {please try again.*: $} {
      send_user -- "\[-] Incorrect password. Enter the $level password: "
      expect_user -re {^(.*)\n$}
      set updated_pass $expect_out(1,string)
      send -- "$updated_pass\r"
      exp_continue
    
    } -re {.assword: $} {
      if { "$lpass" ne "?" } {
        send -- "$lpass\r"
        exp_continue
      }
      send_user -- "\[*] Enter the $level password: "
      expect_user -re {^(.*)\n$}
      set updated_pass $expect_out(1,string)
      send -- "$updated_pass\r"
      exp_continue
    
    } -re {\$ $} {
      if { "$updated_pass" ne "?" } {
        # Save password if it is different from the saved password
        update_password_file "$lname" "$updated_pass"
        send_user -- "\[+] Saved password.\n"
      }
      send_user -- "\[+] Successfully logged in as $level.\n"
      send -- "\r"
      interact
    
    } timeout {
      send_user -- "\[-] The connection timed out.\n"
      return 1
    }
  }
  return 0
}

###[ MAIN FUNCTION ]#####################################
proc main { args_list } {
  set level [lindex $args_list 0]
  set lnum ""
  set lname ""
  set lpass ""
  set rhost ""
  set rport ""

  parse_level "$level" lname lnum
  validate_level "$lname" "$lnum" rhost rport
  get_level_password "$level" lpass

  # Clean up global namespace
  #array unset ::LEVELS_DATA

  source utils.tcl
  return
  
  if { "$lname" eq "natas" } {
    # Natas levels are accessed with a web browser
    handle_natas_levels "$level" "$lpass"
  } else {
    # Connect to all other levels via Expect + ssh
    connect_to_level "$rhost" "$rport" "$level" "$lpass"
  }

  return 0
}

###[ RUN MAIN PROGRAM ]##################################
if { $argc != 1 } {
  show_usage "$argv0"
  exit 1
} else {
  main $argv
  exit 0
}