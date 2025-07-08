#!/bin/bash

# === Parse arguments ===
CLUSTER_NAME="$1"
TARBALL_BASENAME="$2"   # e.g. results_20250629_121000.tar.gz

if [[ -z "$CLUSTER_NAME" || -z "$TARBALL_BASENAME" ]]; then
    echo "Usage: $(basename $0) <ClusterName> <TarballFilename>"
    exit 1
fi

# === Load configuration ===
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$SCRIPT_DIR/.."
CONFIG_FILE="$ROOT_DIR/config/cluster.json"

REMOTE_USER=$(jq -r ".$CLUSTER_NAME.REMOTE_USER" "$CONFIG_FILE")
REMOTE_SERVER=$(jq -r ".$CLUSTER_NAME.REMOTE_SERVER" "$CONFIG_FILE")
REMOTE_DIR=$(jq -r ".$CLUSTER_NAME.REMOTE_RESULTS_DIR" "$CONFIG_FILE")

echo "DEBUG: REMOTE_DIR=$REMOTE_DIR"

# === Paths ===
REMOTE_PATH="$REMOTE_DIR/$TARBALL_BASENAME"
LOCAL_RESULTS_HPC_DIR="$ROOT_DIR/Results_HPC"
LOCAL_TARBALL="$LOCAL_RESULTS_HPC_DIR/$TARBALL_BASENAME"

# Extract timestamp from filename to create a folder
TIMESTAMP="${TARBALL_BASENAME%.tar.gz}"  # remove .tar.gz
TARGET_EXTRACT_DIR="$LOCAL_RESULTS_HPC_DIR/$TIMESTAMP"

# === Transfer tarball ===
echo "📦 Transferring $TARBALL_BASENAME from $REMOTE_SERVER..."

mkdir -p "$LOCAL_RESULTS_HPC_DIR"
scp "$REMOTE_USER@$REMOTE_SERVER:$REMOTE_PATH" "$LOCAL_TARBALL"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: File transfer failed"
    exit 1
fi

# === Extract tarball into timestamped folder ===
mkdir -p "$TARGET_EXTRACT_DIR"
tar -xvzf "$LOCAL_TARBALL" -C "$TARGET_EXTRACT_DIR"
rm "$LOCAL_TARBALL"

echo "✅ Results unpacked into $TARGET_EXTRACT_DIR"
