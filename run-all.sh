#!/bin/bash

if [ -z "$1" ]; then
  echo "Must have running NiFi with input port, specify id as arg 1"
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

find "$DIR/templates/" -name '*.xml' -exec "$DIR/run.sh" {} "$1" \;
