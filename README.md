# OTW Level Connector (in-progress)

A shell script that makes the process of connecting to [OverTheWire](https://overthewire.org/wargames/ "OTW")
levels quicker and more convenient and keeps track of the level passwords
that the user has uncovered.

## Planned Features

- Stores the level passwords you've uncovered in a local file.
- Connect to a level and start working by simply providing the level
  name (if the level's password has been stored; otherwise just enter it
  during the connection process as per usual).

## Requirements

- ssh
- expect

## Usage

```
usage: ./otw.exp <LEVEL>
       ./otw.exp --password <PASSWORD> --level <LEVEL>
```

## Examples

```bash
# Connects to the OTW bandit 21 level via SSH, prompting for the
# level's password during the connection process.
./otw.exp bandit21

# Stores a (p)assword for the OTW bandit 21 (l)evel so that
# connecting to the level does not prompt for a password.
./otw.exp -p deadbeef -l bandit21  <-- Do this once.

./otw.exp bandit21  <----------------- And from now on this will
                                       connect automatically to
                                       the level.
```
