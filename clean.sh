#!/bin/bash

set -e

# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-which-directory-it-is-stored-in#answer-246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "$DIR" ]; then
  echo "Couldn't detect directory, exiting"
  exit 1
fi

if [ -e "$DIR/target" ]; then
  "$DIR/target/teardown.sh"
  rm -r "$DIR/target"
fi
