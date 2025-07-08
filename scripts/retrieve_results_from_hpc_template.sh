#!/bin/bash

CLUSTER_NAME="$1"
TARBALL_BASENAME="$2"   # e.g. results_20250624_183000.tar.gz

if [[ -z "$CLUSTER_NAME" || -z "$TARBALL_BASENAME" ]]; then
    echo "Usage: $(basename $0) <Solstorm> <TarballFilename>"
    exit 1
fi

# Load config
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$SCRIPT_DIR/.."
CONFIG_FILE="$ROOT_DIR/config/cluster.json"

REMOTE_USER=$(jq -r ".$CLUSTER_NAME.REMOTE_USER" "$CONFIG_FILE")
REMOTE_SERVER=$(jq -r ".$CLUSTER_NAME.REMOTE_SERVER" "$CONFIG_FILE")
REMOTE_DIR=$(jq -r ".$CLUSTER_NAME.REMOTE_DIR" "$CONFIG_FILE")

# Define remote and local paths
REMOTE_PATH="$REMOTE_DIR/$TARBALL_BASENAME"
LOCAL_RESULTS_DIR="$ROOT_DIR/Results"
LOCAL_TARBALL="$LOCAL_RESULTS_DIR/$TARBALL_BASENAME"

echo "Transferring $TARBALL_BASENAME from $REMOTE_SERVER..."

# Ensure local results directory exists and is empty
rm -rf "$LOCAL_RESULTS_DIR"
mkdir -p "$LOCAL_RESULTS_DIR"

scp "$REMOTE_USER@$REMOTE_SERVER:$REMOTE_PATH" "$LOCAL_TARBALL"

if [ $? -ne 0 ]; then
    echo "ERROR: File transfer failed"
    exit 1
fi

# Extract
tar -xvzf "$LOCAL_TARBALL" -C "$LOCAL_RESULTS_DIR"
rm "$LOCAL_TARBALL"

echo "Results unpacked into $LOCAL_RESULTS_DIR"
