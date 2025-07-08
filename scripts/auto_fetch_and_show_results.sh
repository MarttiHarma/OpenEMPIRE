#!/bin/bash
#------| Script to retrieve results from HPC and launch local visualization |------#
# Usage: sh scripts/auto_fetch_and_show_results.sh Solstorm

# === Step 0: Input validation ===
if [ "$#" -ne 1 ]; then
    echo "Usage: $(basename $0) <cluster_name>"
    echo "Cluster name should be one of: Solstorm, IDUN"
    exit 1
fi

CLUSTER="$1"

# === Step 1: Determine base paths ===
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/.."

# Load cluster config
CONFIG_FILE="$PROJECT_DIR/config/cluster.json"
REMOTE_USER=$(jq -r ".$CLUSTER.REMOTE_USER" "$CONFIG_FILE")
REMOTE_SERVER=$(jq -r ".$CLUSTER.REMOTE_SERVER" "$CONFIG_FILE")
REMOTE_RESULTS_DIR=$(jq -r ".$CLUSTER.REMOTE_RESULTS_DIR" "$CONFIG_FILE")

LOCAL_RESULTS_HPC_DIR="$PROJECT_DIR/Results_HPC"

POSTPROCESS_SCRIPT="$PROJECT_DIR/scripts/postprocess_results.sh"
VALIDATION_SCRIPT="$PROJECT_DIR/scripts/validate_results.py"
STREAMLIT_APP="$PROJECT_DIR/app/main.py"

# === Step 2: Trigger postprocessing on cluster ===
echo "⚙️  Triggering postprocessing on cluster '$CLUSTER'..."

# Run the script remotely and capture the absolute tarball path
REMOTE_TARBALL_PATH=$(ssh "$REMOTE_USER@$REMOTE_SERVER" "bash ~/OpenEmpire/scripts/postprocess_results.sh" | tail -n 1)

if [ $? -ne 0 ]; then
    echo "❌ Postprocessing failed. Aborting."
    exit 1
fi

# Extract just the basename
TARBALL_BASENAME=$(basename "$REMOTE_TARBALL_PATH")
LOCAL_TARBALL="$LOCAL_RESULTS_HPC_DIR/$TARBALL_BASENAME"

echo "📦 Tarball created remotely: $REMOTE_TARBALL_PATH"
echo "📦 Preparing to transfer to local: $LOCAL_TARBALL"

# === Step 3: Fetch tarball directly from cluster ===
mkdir -p "$LOCAL_RESULTS_HPC_DIR"

echo "📦 Transferring $TARBALL_BASENAME from $REMOTE_SERVER..."
scp "$REMOTE_USER@$REMOTE_SERVER:$REMOTE_TARBALL_PATH" "$LOCAL_TARBALL"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: File transfer failed"
    exit 1
fi

# === Step 4: Extract tarball ===
# Extract timestamp folder name (without .tar.gz)
TIMESTAMP="${TARBALL_BASENAME%.tar.gz}"
TARGET_EXTRACT_DIR="$LOCAL_RESULTS_HPC_DIR/$TIMESTAMP"

mkdir -p "$TARGET_EXTRACT_DIR"
tar -xvzf "$LOCAL_TARBALL" -C "$TARGET_EXTRACT_DIR"
rm "$LOCAL_TARBALL"

echo "✅ Results unpacked into $TARGET_EXTRACT_DIR"

# === Step 5: Validate the results ===
echo "🔍 Validating extracted results..."
PYTHON_EXEC="C:/Conda/python.exe"
$PYTHON_EXEC "$VALIDATION_SCRIPT"
if [ $? -ne 0 ]; then
    echo "❌ Validation failed. Streamlit app will not be launched."
    exit 1
fi

# === Step 6: Launch Streamlit app ===
echo "🚀 Launching Streamlit dashboard..."
cd "$PROJECT_DIR"
streamlit run "$STREAMLIT_APP"
