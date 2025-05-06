#!/bin/bash

SNAPSHOT_MODE=false
for arg in "$@"; do
  if [ "$arg" == "--snapshot" ]; then
    SNAPSHOT_MODE=true
  else
    VERSION_ARG="$arg"
  fi
done

if [ "$SNAPSHOT_MODE" = true ]; then
    if ! PREVIOUS_TAG=$(git describe --tags --abbrev=0); then
        echo "Error: Failed to get previous git tag. Are you in a git repository with tags?"
        exit 1
    fi
    PREVIOUS_TAG="${PREVIOUS_TAG#v}"
    
    if ! COMMIT_HASH=$(git rev-parse --short=7 HEAD); then
        echo "Error: Failed to get git commit hash. Are you in a git repository?"
        exit 1
    fi
    
    NEW_VERSION="${PREVIOUS_TAG}-SNAPSHOT-${COMMIT_HASH}"
    echo "Creating snapshot version: $NEW_VERSION"
else
    if [ -z "$VERSION_ARG" ]; then
        echo "Usage: $0 <new_version> or $0 --snapshot"
        echo "Example: $0 0.121.0"
        exit 1
    fi
    NEW_VERSION="$VERSION_ARG"
fi

CONFIG_FILE="./distributions/axoflow-otel-collector/manifest.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: File $CONFIG_FILE not found!"
    exit 1
fi

# Use sed with backup to replace the version line
sed -i.bak "s/^\([ ]*version:[ ]*\)[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*.*/\1$NEW_VERSION/" "$CONFIG_FILE"

if grep -q "version: $NEW_VERSION" "$CONFIG_FILE"; then
    echo "Version successfully updated to $NEW_VERSION in $CONFIG_FILE"
else
    echo "Failed to update version. Most probably the version has already been updated."
    exit 1
fi
