#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MINIFI_ASSEMBLY_DIR="$1/minifi-assembly/target"
MINIFI_ZIP_FILE="$(find "$MINIFI_ASSEMBLY_DIR" -maxdepth 1 -name 'minifi*.zip' | head -n 1)"

ARCHIVE_DIR="$DIR/archive"
TOOLKIT_DIR="$DIR/toolkit"
CONF_DIR="$DIR/conf"

ARCHIVE="$ARCHIVE_DIR/minifi-archive.zip"

MINIFI_TOOLKIT_DIR="$1/minifi-toolkit/minifi-toolkit-assembly/target"
MINIFI_TOOLKIT_ZIP_FILE="$(find "$MINIFI_TOOLKIT_DIR" -maxdepth 1 -name 'minifi*.zip' | head -n 1)"

rm -r "$ARCHIVE_DIR"
mkdir "$ARCHIVE_DIR"
cp "$MINIFI_ZIP_FILE" "$ARCHIVE"

rm -r "$TOOLKIT_DIR"
mkdir "$TOOLKIT_DIR"
unzip -d "$TOOLKIT_DIR" "$MINIFI_TOOLKIT_ZIP_FILE"

rm -r "$CONF_DIR"
mkdir "$CONF_DIR"
