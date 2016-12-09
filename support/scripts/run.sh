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

OUTPUT_DIR="$RUN_DIR/output"

if [ -e "$OUTPUT_DIR" ]; then
  rm -rf "$OUTPUT_DIR"
fi

mkdir "$OUTPUT_DIR"

MINIFI_LIB_DIR="$RUN_DIR/lib"

if [ -e "$MINIFI_LIB_DIR" ]; then
  rm -rf "$MINIFI_LIB_DIR"
fi

mkdir "$MINIFI_LIB_DIR"

MINIFI_JAR_DIR="$RUN_DIR/jars"

if [ -e "$MINIFI_JAR_DIR" ]; then
  rm -rf "$MINIFI_JAR_DIR"
fi

mkdir "$MINIFI_JAR_DIR"

TOOLKIT_DIR="$DIR/toolkit"
ARCHIVE_DIR="$DIR/archive"
NIFI_DIR="$DIR/nifi"
ARCHIVE="$(find "$ARCHIVE_DIR" -maxdepth 1 -name 'minifi*.zip' | head -n 1)"

unzip -p "$ARCHIVE" "$(unzip -l "$ARCHIVE" | grep "conf/logback.xml" | awk '{print $NF}')" > "$CONF_DIR/logback.xml"

sed -i '' 's/^\(.*org\.apache\.nifi\.controller\.repository\.StandardProcessSession.*level="\).*\(".*$\)/\1INFO\2/g' "$CONF_DIR/logback.xml"

EXTENSION="$(echo "$1" | sed 's/.*\.//g')"

if [ "$EXTENSION" = "xml" ]; then
  CONFIG_SCRIPT="$(find $TOOLKIT_DIR -name config.sh | head -n 1)"

  chmod +x "$CONFIG_SCRIPT"
  "$CONFIG_SCRIPT" transform "$1" "$CONF_DIR/config.yml"
  if [ -e "$RUN_DIR/post_transform.sh" ]; then
    "$RUN_DIR/post_transform.sh"
  fi
elif [ "$EXTENSION" = "yml" ]; then
  cp "$1" "$CONF_DIR/config.yml"
else
  "Unknown extension $EXTENSION for $1"
  exit 1
fi

REQUIRED_NARS="$(find "$RUN_DIR" -maxdepth 1 -name 'required_nars' | head -n 1)"

if [ -n "$REQUIRED_NARS" ]; then
  for i in `cat "$REQUIRED_NARS"`; do
    NAR_FILE="$(find "$NIFI_DIR" -type f -name "$i" | head -n 1)"
    if [ -z "$NAR_FILE" ]; then
      echo "Unable to find $i in $NIFI_DIR"
      exit 1
    fi
    cp "$NAR_FILE" "$MINIFI_LIB_DIR"
  done
fi

REQUIRED_JARS="$(find "$RUN_DIR" -maxdepth 1 -name 'required_jars' | head -n 1)"

if [ -n "$REQUIRED_JARS" ]; then
  for i in `cat "$REQUIRED_JARS"`; do
    JAR_FILE="$(find "$DIR/jars" -type f -name "$i" | head -n 1)"
    if [ -z "$JAR_FILE" ]; then
      echo "Unable to find $i in $NIFI_DIR"
      exit 1
    fi
    cp "$JAR_FILE" "$MINIFI_JAR_DIR"
  done
fi

EXPECTED_FILE="$(find "$RUN_DIR" -maxdepth 1 -name 'expected_*' | head -n 1)"

trap inttrap INT

function inttrap() {
  docker kill minifi
}

if [ -z "$EXPECTED_FILE" ]; then
  echo "Couldn't find expected file in $RUN_DIR, running indefinitely"
  docker run -ti --rm -v /dev/urandom:/dev/random -v "$ARCHIVE_DIR":/opt/minifi-archive -v "$CONF_DIR":/opt/minifi-conf -v "$MINIFI_LIB_DIR":/opt/minifi-lib -v "$MINIFI_JAR_DIR":/opt/minifi-jars --net minifi --hostname minifi --name minifi minifi 2>&1 | tee "$OUTPUT_DIR/minifi.log"
else
  EXPECTED_LINE="$(head -n 1 "$EXPECTED_FILE")"
  EXPECTED_NUM="$(echo "$EXPECTED_FILE" | sed 's/.*expected_\(.*\)$/\1/g')"

  echo "Looking for \"$EXPECTED_LINE\" $EXPECTED_NUM times"
  FOUND_COUNT=0

  docker run --rm -v /dev/urandom:/dev/random -v "$ARCHIVE_DIR":/opt/minifi-archive -v "$CONF_DIR":/opt/minifi-conf -v "$MINIFI_LIB_DIR":/opt/minifi-lib -v "$MINIFI_JAR_DIR":/opt/minifi-jars --net minifi --hostname minifi --name minifi minifi 2>&1 > "$OUTPUT_DIR/minifi.log" &

  # http://superuser.com/questions/270529/monitoring-a-file-until-a-string-is-found#answer-449307
  tail -f "$OUTPUT_DIR/minifi.log" | while read LOGLINE
  do
    if [[ "$LOGLINE" =~ $EXPECTED_LINE ]]; then
      ((FOUND_COUNT++))
      echo "minifi log (found $FOUND_COUNT): $LOGLINE" >> "$OUTPUT_DIR/analysis.log"
      if [ "$FOUND_COUNT" -eq "$EXPECTED_NUM" ]; then
        echo "Found expected line $FOUND_COUNT times." >> "$OUTPUT_DIR/analysis.log"
        echo "Scenario $1 successful" >> "$OUTPUT_DIR/analysis.log"
        docker kill minifi
        pkill -P $$ tail
      fi
    fi
    echo "$1 (found $FOUND_COUNT): $LOGLINE"
  done
fi
