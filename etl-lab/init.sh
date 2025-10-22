#!/bin/bash
set -eu

# Directories to create (relative to where this script is run)
DIRS="
data/db
data/kafka
data/nifi/data
data/nifi/logs
data/pgadmin
work
"

echo "Creating directories..."
for d in $DIRS; do
  mkdir -p "$d"
done
echo "Done."

# JDBC driver details
JAR_VER="42.7.4"
JAR_NAME="postgresql-$JAR_VER.jar"
DEST="data/nifi/data/$JAR_NAME"
URL="https://repo1.maven.org/maven2/org/postgresql/postgresql/$JAR_VER/$JAR_NAME"

# Download if missing or empty
if [ -s "$DEST" ]; then
  echo "JAR already present: $DEST"
else
  echo "Downloading $JAR_NAME to $DEST ..."
  if command -v curl >/dev/null 2>&1; then
    curl -fL "$URL" -o "$DEST"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$DEST" "$URL"
  else
    echo "Error: please install curl or wget to download $JAR_NAME" >&2
    exit 1
  fi
  echo "Saved: $DEST"
fi

echo "All done."
