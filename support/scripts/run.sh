#!/bin/bash

set -e

# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-which-directory-it-is-stored-in#answer-246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

RUN_DIR="$DIR/$(dirname $1)"

if [ -z "$RUN_DIR" ]; then
  echo "Couldn't resolve run dir"
  exit 1
fi

if [ ! -e "$RUN_DIR" ]; then
  echo "Run dir $RUN_DIR doesn't exist"
  exit 1
fi

CONF_DIR="$RUN_DIR/conf"

if [ -e "$CONF_DIR" ]; then
  rm -rf "$CONF_DIR"
fi

mkdir "$CONF_DIR"

TOOLKIT_DIR="$DIR/toolkit"
ARCHIVE_DIR="$DIR/archive"

EXTENSION="$(echo "$1" | sed 's/.*\.//g')"

if [ "$EXTENSION" = "xml" ]; then
  CONFIG_SCRIPT="$(find $TOOLKIT_DIR -name config.sh | head -n 1)"

  chmod +x "$CONFIG_SCRIPT"
  "$CONFIG_SCRIPT" transform "$1" "$CONF_DIR/config.yml"
elif [ "$EXTENSION" = "yml" ]; then
  cp "$1" "$CONF_DIR/config.yml"
else
  "Unknown extension $EXTENSION for $1"
  exit 1
fi

docker run -ti -v /dev/urandom:/dev/random -v "$ARCHIVE_DIR":/opt/minifi-archive -v "$CONF_DIR":/opt/minifi-conf --rm --net minifi --hostname minifi --name minifi minifi
