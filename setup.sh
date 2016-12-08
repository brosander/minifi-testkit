#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "First argument of minifi location expected"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Second argument of nifi archive expected"
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MINIFI_ASSEMBLY_DIR="$1/minifi-assembly/target"
MINIFI_ZIP_FILE="$(find "$MINIFI_ASSEMBLY_DIR" -maxdepth 1 -name 'minifi*.zip' | head -n 1)"

TARGET_DIR="$DIR/target"
ARCHIVE_DIR="$TARGET_DIR/archive"
TOOLKIT_DIR="$TARGET_DIR/toolkit"
NIFI_DIR="$TARGET_DIR/nifi"

ARCHIVE="$ARCHIVE_DIR/minifi-archive.zip"

MINIFI_TOOLKIT_DIR="$1/minifi-toolkit/minifi-toolkit-assembly/target"
MINIFI_TOOLKIT_ZIP_FILE="$(find "$MINIFI_TOOLKIT_DIR" -maxdepth 1 -name 'minifi*.zip' | head -n 1)"

function buildImage() {
  local TAG="$1"
  local CMD="docker build -t $TAG ."
  local DIR="$2"

  echo "Building Dockerfile in $DIR:"

  if [ -n "$3" ]; then
    local CMD="$( echo "$3" | sed "s/TAG_ARG/$TAG/g")"
  fi

  (cd "$DIR" && eval "$CMD")
  if [ $? -ne 0 ]; then
    echo "$CMD FAILED in Directory: $DIR"
    exit 1
  else
    echo "$CMD SUCCEEDED"
  fi
  echo
}

if [ ! -e "$DIR/dev-dockerfiles" ]; then
  git clone https://github.com/brosander/dev-dockerfiles.git
fi

"$DIR/clean.sh"

mkdir "$TARGET_DIR"
cp -r "$DIR/support" "$TARGET_DIR"
mv "$TARGET_DIR/support/scripts"/* "$TARGET_DIR"
rm -r "$TARGET_DIR/support/scripts"
cp -r "$DIR/scenarios" "$TARGET_DIR"

mkdir "$ARCHIVE_DIR"
cp "$MINIFI_ZIP_FILE" "$ARCHIVE"

mkdir "$TOOLKIT_DIR"
unzip -d "$TOOLKIT_DIR" "$MINIFI_TOOLKIT_ZIP_FILE"

mkdir "$NIFI_DIR"
unzip -d "$NIFI_DIR" "$2"

unzip -p "$2" "$(unzip -l "$2" | grep nifi\\.properties | awk '{print $NF}')" > "$TARGET_DIR/support/nifi/nifi.properties"
sed -i '' 's/^nifi.remote.input.socket.port=.*/nifi.remote.input.socket.port=8081/g' "$TARGET_DIR/support/nifi/nifi.properties"

cp -r "$TARGET_DIR/support/nifi" "$TARGET_DIR/support/nifi-noproxy"
sed -i '' 's/^nifi.remote.input.host=.*/nifi.remote.input.host=nifi.minifi/g' "$TARGET_DIR/support/nifi-noproxy/nifi.properties"
sed -i '' 's/^nifi.web.http.host=.*/nifi.web.http.host=nifi.minifi/g' "$TARGET_DIR/support/nifi-noproxy/nifi.properties"

cp -r "$TARGET_DIR/support/nifi" "$TARGET_DIR/support/nifi-proxy"
sed -i '' 's/^nifi.remote.input.host=.*/nifi.remote.input.host=nifi.minifi2/g' "$TARGET_DIR/support/nifi-proxy/nifi.properties"
sed -i '' 's/^nifi.web.http.host=.*/nifi.web.http.host=nifi.minifi2/g' "$TARGET_DIR/support/nifi-proxy/nifi.properties"

echo
echo "Generating docker-compose.yml"

echo "version: '2'" > "$TARGET_DIR/docker-compose.yml"
echo "services:" >> "$TARGET_DIR/docker-compose.yml"

echo "  squid-pass:" >> "$TARGET_DIR/docker-compose.yml"
echo "    container_name: minifi-testkit-squid-pass" >> "$TARGET_DIR/docker-compose.yml"
echo "    image: alpine-squid" >> "$TARGET_DIR/docker-compose.yml"
echo "    restart: always" >> "$TARGET_DIR/docker-compose.yml"
echo "    ports:" >> "$TARGET_DIR/docker-compose.yml"
echo "      - 3128" >> "$TARGET_DIR/docker-compose.yml"
echo "    networks:" >> "$TARGET_DIR/docker-compose.yml"
echo "      minifi:" >> "$TARGET_DIR/docker-compose.yml"
echo "        aliases:" >> "$TARGET_DIR/docker-compose.yml"
echo "          - squidp.minifi" >> "$TARGET_DIR/docker-compose.yml"
echo "      minifi2:" >> "$TARGET_DIR/docker-compose.yml"
echo "        aliases:" >> "$TARGET_DIR/docker-compose.yml"
echo "          - squidp.minifi2" >> "$TARGET_DIR/docker-compose.yml"
echo "    volumes:" >> "$TARGET_DIR/docker-compose.yml"
echo "      - $TARGET_DIR/support/squid/pass:/opt/squid-conf" >> "$TARGET_DIR/docker-compose.yml"

echo "  squid-nopass:" >> "$TARGET_DIR/docker-compose.yml"
echo "    container_name: minifi-testkit-squid-nopass" >> "$TARGET_DIR/docker-compose.yml"
echo "    image: alpine-squid" >> "$TARGET_DIR/docker-compose.yml"
echo "    restart: always" >> "$TARGET_DIR/docker-compose.yml"
echo "    ports:" >> "$TARGET_DIR/docker-compose.yml"
echo "      - 3128" >> "$TARGET_DIR/docker-compose.yml"
echo "    networks:" >> "$TARGET_DIR/docker-compose.yml"
echo "      minifi:" >> "$TARGET_DIR/docker-compose.yml"
echo "        aliases:" >> "$TARGET_DIR/docker-compose.yml"
echo "          - squidnp.minifi" >> "$TARGET_DIR/docker-compose.yml"
echo "      minifi2:" >> "$TARGET_DIR/docker-compose.yml"
echo "        aliases:" >> "$TARGET_DIR/docker-compose.yml"
echo "          - squidnp.minifi2" >> "$TARGET_DIR/docker-compose.yml"
echo "    volumes:" >> "$TARGET_DIR/docker-compose.yml"
echo "      - $TARGET_DIR/support/squid/nopass:/opt/squid-conf" >> "$TARGET_DIR/docker-compose.yml"

echo "  nifi-noproxy:" >> "$TARGET_DIR/docker-compose.yml"
echo "    container_name: minifi-testkit-nifi-noproxy" >> "$TARGET_DIR/docker-compose.yml"
echo "    image: nifi" >> "$TARGET_DIR/docker-compose.yml"
echo "    restart: always" >> "$TARGET_DIR/docker-compose.yml"
echo "    ports:" >> "$TARGET_DIR/docker-compose.yml"
echo "      - 8080" >> "$TARGET_DIR/docker-compose.yml"
echo "    networks:" >> "$TARGET_DIR/docker-compose.yml"
echo "      minifi:" >> "$TARGET_DIR/docker-compose.yml"
echo "        aliases:" >> "$TARGET_DIR/docker-compose.yml"
echo "          - nifi.minifi" >> "$TARGET_DIR/docker-compose.yml"
echo "    volumes:" >> "$TARGET_DIR/docker-compose.yml"
echo "      - $TARGET_DIR/support/nifi-noproxy:/opt/nifi-conf" >> "$TARGET_DIR/docker-compose.yml"
echo "      - /dev/urandom:/dev/random" >> "$TARGET_DIR/docker-compose.yml"
echo "      - $2:/opt/nifi-archive/nifi-archive.zip" >> "$TARGET_DIR/docker-compose.yml"

echo "  nifi-proxy:" >> "$TARGET_DIR/docker-compose.yml"
echo "    container_name: minifi-testkit-nifi-proxy" >> "$TARGET_DIR/docker-compose.yml"
echo "    image: nifi" >> "$TARGET_DIR/docker-compose.yml"
echo "    restart: always" >> "$TARGET_DIR/docker-compose.yml"
echo "    ports:" >> "$TARGET_DIR/docker-compose.yml"
echo "      - 8080" >> "$TARGET_DIR/docker-compose.yml"
echo "    networks:" >> "$TARGET_DIR/docker-compose.yml"
echo "      minifi2:" >> "$TARGET_DIR/docker-compose.yml"
echo "        aliases:" >> "$TARGET_DIR/docker-compose.yml"
echo "          - nifi.minifi2" >> "$TARGET_DIR/docker-compose.yml"
echo "    volumes:" >> "$TARGET_DIR/docker-compose.yml"
echo "      - $TARGET_DIR/support/nifi-proxy:/opt/nifi-conf" >> "$TARGET_DIR/docker-compose.yml"
echo "      - /dev/urandom:/dev/random" >> "$TARGET_DIR/docker-compose.yml"
echo "      - $2:/opt/nifi-archive/nifi-archive.zip" >> "$TARGET_DIR/docker-compose.yml"

echo  >> "$TARGET_DIR/docker-compose.yml"
echo  >> "$TARGET_DIR/docker-compose.yml"
echo "networks:" >> "$TARGET_DIR/docker-compose.yml"
echo "  minifi:" >> "$TARGET_DIR/docker-compose.yml"
echo "    external: true" >> "$TARGET_DIR/docker-compose.yml"
echo "  minifi2:" >> "$TARGET_DIR/docker-compose.yml"
echo "    external: true" >> "$TARGET_DIR/docker-compose.yml"

buildImage nifi "$DIR/dev-dockerfiles/nifi/ubuntu" "./build.sh"
buildImage minifi "$DIR/dev-dockerfiles/minifi/java/ubuntu" "./build.sh"
buildImage alpine-squid "$DIR/dev-dockerfiles/squid/alpine"
buildImage apache-utils "$DIR/dev-dockerfiles/apache/utils" "./build.sh"
docker run -ti --rm apache-utils sh -c "echo password | htpasswd -n -i username" | grep -v -e '^[[:space:]]*$' > "$TARGET_DIR/support/squid/pass/passwords"

if [ -z "`docker network ls | awk '{print $2}' | grep '^minifi$'`" ]; then
  echo "Creating minifi network"
  docker network create --gateway 172.26.1.1 --subnet 172.26.1.0/24 minifi
else
  echo "minifi network already exists, not creating"
fi

if [ -z "`docker network ls | awk '{print $2}' | grep '^minifi2$'`" ]; then
  echo "Creating minifi2 network"
  docker network create --gateway 172.27.1.1 --subnet 172.27.1.0/24 minifi2
else
  echo "minifi2 network already exists, not creating"
fi

