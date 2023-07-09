# OverTheWire Level Connector

A shell script written in [Expect](https://www.tcl.tk/software/tcltk/ "Expect") that makes the process of connecting
to [OverTheWire](https://overthewire.org/wargames/ "OTW") levels quicker and more convenient.

[![asciicast](https://asciinema.org/a/595781.svg)](https://asciinema.org/a/595781)

## Features

- Automates SSH login to remote OTW levels.
- Stores the level passwords you've uncovered in a local file.
- Connect to a level and start working by simply providing the level
  name (if the level's password has been stored; otherwise just enter it
  when prompted during the connection process).

## Requirements

- [expect](https://core.tcl-lang.org/expect/home "Expect")
- [tcl](https://www.tcl.tk/software/tcltk/ "Tcl")
- [ssh](https://www.openssh.com/ "SSH")

## Usage

```
usage: ./otw.tcl [-h] [-p PASSWORD] [-l] LEVEL
```

## Examples

```bash
# Connects to the OTW bandit 0 level via SSH, prompting for the
# level's password during the connection process.
./otw.tcl bandit0

# Stores a (p)assword for the OTW bandit 0 (l)evel so that
# connecting to the level does not prompt for a password.
./otw.tcl -p bandit0 -l bandit0  <---- Do this once.

./otw.tcl bandit0  <------------------ And from now on this will
                                       connect automatically to
                                       the level.
```
