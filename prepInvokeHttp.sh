#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sed "s/b23a4621-cf19-42e6-967c-ffd3716e6a24/$1/g" "$DIR/templates/InvokeHttpMiNiFiTemplateTest.xml" > /tmp/InvokeHttpMiNiFiTemplateTest.xml
"$(find "$DIR/toolkit" -name config.sh | head -n 1)" transform /tmp/InvokeHttpMiNiFiTemplateTest.xml "$DIR/conf/config.yml"
