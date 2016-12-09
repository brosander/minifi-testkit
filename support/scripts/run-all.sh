#!/bin/bash

if [ -n "$2" ]; then
  MIN="$1"
  MAX="$2"
elif [ -n "$1" ]; then
  MIN="1"
  MAX="$1"
else
  MIN="1"
  MAX="3"
fi

echo "Min version: $MIN max version: $MAX"

# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-which-directory-it-is-stored-in#answer-246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$DIR"

find scenarios -mindepth 4 -maxdepth 4 -type d -name 'conf' -exec rm -r {} \;
find scenarios -mindepth 4 -maxdepth 4 -type d -name 'output' -exec rm -r {} \;

find scenarios/ -maxdepth 3 -mindepth 3 -type d -name '*ml' -exec bash -c 'mkdir "$0/output" && touch "$0/output/NOT_RUN"' {} \;

for i in $(seq $MIN $MAX); do
  echo "Finding files in v$i"
  SCENARIOS="$(find "scenarios/v$i" -maxdepth 3 -type f -name "*.xml" && find "scenarios/v$i" -maxdepth 3 -type f -name "*.yml")"
  for i in $SCENARIOS; do
    SCENARIO_DIR="$(dirname "$i")"
    ./run.sh "$i"
    while [ -n "$(docker ps | awk '{print $NF}' | grep "^minifi$")" ]; do
      docker kill minifi
    done
    while [ -n "$(docker ps -a | awk '{print $NF}' | grep "^minifi$")" ]; do
      docker rm minifi
    done
  done
done

./analyze.sh
