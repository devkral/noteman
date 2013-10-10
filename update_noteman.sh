#!/usr/bin/env bash

#usage 
if [ "$1" = "" ] || [ "$1" = "--help" ] || [ ! -e "$1" ]; then
  echo "Usage: <path to old noteman> [new noteman]"
  exit 1
fi

old_noteman="$1"

if [ "$2" = "" ]; then
  new_noteman="$(dirname "$0")/noteman.sh"
else
  new_noteman="$2"
fi






vimdiff "$old_noteman" "$new_noteman"



