#!/usr/bin/bash

if [ $# -ne 2 ]; then
  echo "usage: $0 from_ext to_ext"
  exit 1
fi

convert_files() {
  local from_ext="$1"
  local to_ext="$2"
  local found_files=0
  local fname=""
  local optchanged=0

  shopt -q nullglob
  if [ $? -ne 0 ]; then
    shopt -s nullglob
    optchanged=1
  fi

  for oldf in *."$from_ext"; do
    found_files=1
    fname="${oldf%%.*}"
    mv -i "$oldf" "${fname}.${to_ext}"
  done

  if [ $optchanged -eq 1 ]; then
    shopt -u nullglob
  fi

  if [ $found_files -eq 0 ]; then
    echo "No .${from_ext} files in current directory."
    return 1
  fi

  return 0
}

convert_files "$1" "$2" && exit 0 || exit 1
