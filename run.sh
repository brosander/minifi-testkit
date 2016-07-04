#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TOOLKIT_DIR="$DIR/toolkit"
ARCHIVE_DIR="$DIR/archive"
CONF_DIR="$DIR/conf"

CONFIG_SCRIPT="$(find $TOOLKIT_DIR -name config.sh | head -n 1)"

chmod +x "$CONFIG_SCRIPT"

"$CONFIG_SCRIPT" transform "$1" "$CONF_DIR/config.yml"

docker run -ti -v "$ARCHIVE_DIR":/opt/minifi-archive -v "$CONF_DIR":/opt/minifi-conf -p 8081:8081 --rm minifi