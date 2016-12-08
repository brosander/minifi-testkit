#!/bin/bash

# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-which-directory-it-is-stored-in#answer-246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$DIR"

SCENARIO_FOLDERS="$(find scenarios -mindepth 3 -maxdepth 3 -type d -name '*ml' | sort)"
SCENARIO_COUNT="$(echo "$SCENARIO_FOLDERS" | wc -l | tr -d ' ')"

OUTPUT_FOLDERS="$(echo "$SCENARIO_FOLDERS" | xargs -I {} find {} -mindepth 1 -maxdepth 1 -type d -name output)"

ANALYSIS_FILES="$(echo "$OUTPUT_FOLDERS" | xargs -I {} find {} -mindepth 1 -maxdepth 1 -type f -name analysis.log)"
ANALYZED_SCENARIOS="$(echo "$ANALYSIS_FILES" | sed 's/\/output\/analysis\.log//g' | sort)"
ANALYSIS_COUNT="$(echo "$ANALYSIS_FILES" | wc -l | tr -d ' ')"

SUCCESSFUL_RUNS="$(echo "$ANALYSIS_FILES" | xargs grep -l "Scenario .* successful" | sed 's/\/output\/analysis\.log//g')"
SUCCESS_COUNT="$(echo "$ANALYSIS_FILES" | wc -l | tr -d ' ')"

echo "Successful scenario count: $SUCCESS_COUNT/$SCENARIO_COUNT"
echo
echo "Successful scenarios:"
echo "$SUCCESSFUL_RUNS"

if [ "$SCENARIO_COUNT" != "$ANALYSIS_COUNT" ]; then
  echo
  echo
  echo "Skipped scenario count: $((SCENARIO_COUNT - ANALYSIS_COUNT))/$SCENARIO_COUNT"
  echo
  echo "Skipped scenarios:"
  echo "$(diff <(echo "$SCENARIO_FOLDERS") <(echo "$ANALYZED_SCENARIOS") | grep "^<" | awk '{print $NF}')"
fi

