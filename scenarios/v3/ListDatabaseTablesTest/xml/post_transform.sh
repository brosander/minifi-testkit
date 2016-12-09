#!/bin/bash

# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-which-directory-it-is-stored-in#answer-246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sed -i '' "s/\(.*Password:\).*/\1 'mysecretpassword'/g" "$DIR/conf/config.yml"
