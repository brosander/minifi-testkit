#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TOOLKIT_DIR="$DIR/toolkit"
ARCHIVE_DIR="$DIR/archive"
CONF_DIR="$DIR/conf"

if [ -n "$1" ]; then
  CONFIG_SCRIPT="$(find $TOOLKIT_DIR -name config.sh | head -n 1)"

  chmod +x "$CONFIG_SCRIPT"

  if [ "InvokeHttpMiNiFiTemplateTest.xml" = "$( basename "$1" )" ]; then
    if [ -z "$2" ]; then
      echo "Must specify input port id as arg 2 for InvokeHttpMiNiFiTemplateTest.xml"
      exit 1
    fi
    
    sed "s/b23a4621-cf19-42e6-967c-ffd3716e6a24/$2/g" "$1" > /tmp/InvokeHttpMiNiFiTemplateTest.xml
    "$CONFIG_SCRIPT" transform "/tmp/InvokeHttpMiNiFiTemplateTest.xml" "$CONF_DIR/config.yml"
  else
    "$CONFIG_SCRIPT" transform "$1" "$CONF_DIR/config.yml"
  fi

  if [ $? -ne 0 ]; then
    exit 1
  fi
fi

docker run -ti -v "$ARCHIVE_DIR":/opt/minifi-archive -v "$CONF_DIR":/opt/minifi-conf -p 8081:8081 --rm --net minifi --hostname minifi --name minifi minifi
