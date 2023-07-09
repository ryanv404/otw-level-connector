# OverTheWire Level Connector

A shell script written in Expect/Tcl that makes the process of connecting
to [OverTheWire](https://overthewire.org/wargames/ "OTW") levels quicker
and more convenient.

## Features

- Stores the level passwords you've uncovered in a local file.
- Connect to a level and start working by simply providing the level
  name (if the level's password has been stored; otherwise just enter it
  during the connection process as per usual and it will be saved for you
  to use in the future).

## Requirements

- Expect/Tcl
- ssh

## Usage

```
usage: ./otw.tcl LEVEL
       ./otw.tcl [-h] [--password PASSWORD] [--level LEVEL]
```

## Examples

```bash
# Connects to the OTW bandit 21 level via SSH, prompting for the
# level's password during the connection process.
./otw.tcl bandit21

# Stores a (p)assword for the OTW bandit 21 (l)evel so that
# connecting to the level does not prompt for a password.
./otw.tcl -p deadbeef -l bandit21  <-- Do this once.

./otw.tcl bandit21  <----------------- And from now on this will
                                       connect automatically to
                                       the level.
```
