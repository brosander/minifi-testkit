#!/bin/bash

# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-which-directory-it-is-stored-in#answer-246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sed -i '' "s/\(.*proxy password:\).*/\1 'password'/g" "$DIR/conf/config.yml"
