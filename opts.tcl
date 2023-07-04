#!/usr/bin/env expect

namespace eval ::myutils {
  variable  test
  array set test {
    read   {readable    {Read access is denied}}
    write  {writable    {Write access is denied}}
    exec   {executable  {Is not executable}}
    exists {exists      {Does not exist}}
    file   {isfile      {Is not a file}}
    dir    {isdirectory {Is not a directory}}
  }
}

proc updateInPlace {args} {
  # Syntax: ?options? file cmd
  # options = -encoding    ENC
  #         | -translation TRA
  #         | -eofchar     ECH
  #         | --
  Spec ReadWritable $args opts fname cmd

  # readFile/cat inlined ...
  set             c [open $fname r]
  SetOptions     $c $opts
  set data [read $c]
  close          $c

  # Transformation. Abort and do not modify the target file if an
  # error was raised during this step.
  lappend cmd $data
  set code [catch {uplevel 1 $cmd} res]
  if {$code} {
  	return -code $code $res
  }

  # writeFile inlined, with careful preservation of old contents
  # until we are sure that the write was ok.
  if {[catch {
      file rename -force $fname ${fname}.bak

      set              o [open $fname w]
      SetOptions      $o $opts
      puts -nonewline $o $res
      close           $o

      file delete -force ${fname}.bak
    } msg]} {
    if {[file exists ${fname}.bak]} {
      catch {
        file rename -force ${fname}.bak $fname
      }
      return -code error $msg
    }
  }
  return
}

proc usage {optlist {usage {options:}}} {
  set str "[getArgv0] $usage\n"
  set longest 20
  set lines {}

  foreach opt [concat $optlist {{- "Forcibly stop option processing"} \
    {help "Print this message"} {? "Print this message"}}] {
    set name "-[lindex $opt 0]"
    if {[regsub -- {\.secret$} $name {} name] == 1} {
      # Hidden option
      continue
    }

    if {[regsub -- {\.arg$} $name {} name] == 1} {
      append name " value"
      set desc "[lindex $opt 2] <[lindex $opt 1]>"
    } else {
      set desc "[lindex $opt 1]"
    }

    set n [string length $name]
    if {$n > $longest} { set longest $n }
    # max not available before 8.5 - set longest [expr {max($longest, )}]
    lappend lines $name $desc
  }

  foreach {name desc} $lines {
    append str "[string trimright [format " %-*s %s" $longest $name $desc]]\n"
  }
  return $str
}

proc test {path codes {msgvar {}} {label {}}} {
  variable test

  if {[string equal $msgvar ""]} {
    set msg ""
  } else {
    upvar 1 $msgvar msg
  }

  if {![string equal $label ""]} {append label { }}

  if {![regexp {^(read|write|exec|exists|file|dir)} $codes]} {
    # Translate single characters into proper codes
    set codes [string map {
    r read w write e exists x exec f file d dir
    } [split $codes {}]]
  }

  foreach c $codes {
    foreach {cmd text} $test($c) break
    if {![file $cmd $path]} {
      set msg "$label\"$path\": $text"
      return 0
    }
  }
  return 1
}

proc ::fileutil::parseopts {basedir args} {
  set pos 0

  foreach a $args {
    incr pos
    switch -glob -- $a {
      --      {break}
      -regexp {set cmd 0}
      -glob   {set cmd 1}
      -*      {return -code error "Unknown option $a"}
      default {incr pos -1 ; break}
    }
  }

  set args [lrange $args $pos end]

  if {[llength $args] != 1} {
    set pname [lindex [info level 0] 0]
    return -code error \
      "wrong#args for \"$pname\", should be\
      \"$pname basedir ?-regexp|-glob? ?--? patterns\""
  }

  set patterns [lindex $args 0]
  return [find $basedir [list $cmd $patterns]]
}


proc getopt {argvVar optstring optVar valVar} {
  upvar 1 $argvVar argsList
  upvar 1 $optVar option
  upvar 1 $valVar value

  set result [getKnownOpt argsList $optstring option value]

  if {$result < 0} {
    # Collapse unknown-option error into any-other-error result.
    set result -1
  }
  return $result
}

proc getKnownOpt {argvVar optstring optVar valVar} {
  upvar 1 $argvVar argsList
  upvar 1 $optVar  option
  upvar 1 $valVar  value

  # default settings for a normal return
  set value ""
  set option ""
  set result 0

  # check if we're past the end of the args list
  if {[llength $argsList] != 0} {

    # if we got -- or an option that doesn't begin with -, return (skipping
    # the --).  otherwise process the option arg.
    switch -glob -- [set arg [lindex $argsList 0]] {
      "--" {set argsList [lrange $argsList 1 end]}
      "--*" -
      "-*" {
        set option [string range $arg 1 end]
        if {[string equal [string range $option 0 0] "-"]} {
          set option [string range $arg 2 end]
        }

        # support for format: [-]-option=value
        set idx [string first "=" $option 1]
        if {$idx != -1} {
          set _val   [string range $option [expr {$idx+1}] end]
          set option [string range $option 0   [expr {$idx-1}]]
        }

        if {[lsearch -exact $optstring $option] != -1} {
          # Booleans are set to 1 when present
          set value 1
          set result 1
          set argsList [lrange $argsList 1 end]
        } elseif {[lsearch -exact $optstring "$option.arg"] != -1} {
          set result 1
          set argsList [lrange $argsList 1 end]

          if {[info exists _val]} {
            set value $_val
          } elseif {[llength $argsList]} {
            set value [lindex $argsList 0]
            set argsList [lrange $argsList 1 end]
          } else {
            set value "Option \"$option\" requires an argument"
            set result -2
          }
        } else {
          # Unknown option.
          set value "Illegal option \"-$option\""
          set result -1
        }
      }
      default {
        # Skip ahead
      }
    }
  }
  return $result
}
