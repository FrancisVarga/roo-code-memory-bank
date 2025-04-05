#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Roo Code Memory Bank Config Setup ---"

# Define GitHub repository information
GITHUB_REPO="FrancisVarga/roo-code-memory-bank"
TEMP_DIR=$(mktemp -d)
TAR_FILE="${TEMP_DIR}/roo-code-memory-bank.tar.gz"

# Cleanup function to be called on exit
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "${TEMP_DIR}"
}

# Set the cleanup function to run on script exit
trap cleanup EXIT

# Check for curl command
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not found in your PATH."
    echo "Please install curl using your distribution's package manager (e.g., sudo apt install curl, sudo yum install curl)."
    exit 1
else
    echo "Found curl executable."
fi

echo "Downloading latest release..."

# Get the latest release URL
echo "Fetching the latest release information..."
DOWNLOAD_URL=$(curl -s -L -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | 
    grep "browser_download_url.*tar.gz" | 
    cut -d '"' -f 4)

if [ -z "${DOWNLOAD_URL}" ]; then
    echo "Error: Could not determine download URL for the latest release."
    echo "Please check your internet connection or repository settings."
    exit 1
fi

echo "Downloading from: ${DOWNLOAD_URL}"
curl -L -o "${TAR_FILE}" "${DOWNLOAD_URL}"

echo "Extracting configuration files..."

# Create extraction directory
mkdir -p "${TEMP_DIR}/extracted"
tar -xzf "${TAR_FILE}" -C "${TEMP_DIR}/extracted"

# Copy configuration files to current directory
echo "Copying configuration files to current directory..."
cp -f "${TEMP_DIR}/extracted/config/"* .

echo "All configuration files installed successfully."
echo "--- Roo Code Memory Bank Config Setup Complete ---"

echo "Scheduling self-deletion of $0..."
# Run deletion in a background subshell to allow the main script to exit first
( sleep 1 && rm -f "$0" ) &

exit 0