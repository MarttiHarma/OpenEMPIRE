#!/bin/bash

# Automatically detect EMPIRE root based on script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EMPIRE_DIR="$SCRIPT_DIR/.."

RUN_ANALYSIS_DIR="$EMPIRE_DIR/Results/run_analysis"
RESULTS_HPC_DIR="$EMPIRE_DIR/Results_HPC"

# Create Results_HPC directory if it doesn't exist
mkdir -p "$RESULTS_HPC_DIR"

# Find the newest subdirectory inside Results/run_analysis
NEWEST_RESULT_DIR=$(find "$RUN_ANALYSIS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)

if [ -z "$NEWEST_RESULT_DIR" ]; then
    echo "ERROR: No result directories found inside $RUN_ANALYSIS_DIR"
    exit 1
fi

# Extract the folder name (timestamped result folder)
TIMESTAMP=$(basename "$NEWEST_RESULT_DIR")

# Define tarball path
TARBALL="$RESULTS_HPC_DIR/results_${TIMESTAMP}.tar.gz"

# Print informational messages prefixed
echo "[INFO] Newest results directory found: $NEWEST_RESULT_DIR"
echo "[INFO] Creating tarball at: $TARBALL"

# Create the tarball containing the newest results folder
tar -czf "$TARBALL" -C "$RUN_ANALYSIS_DIR" "$TIMESTAMP" .


if [ $? -eq 0 ]; then
    # ONLY this line gets printed unprefixed for automation
    echo "$TARBALL"
else
    echo "ERROR: Compression failed"
    exit 1
fi

# Optional: ensure this script remains executable
chmod +x "$SCRIPT_DIR/postprocess_results.sh"
