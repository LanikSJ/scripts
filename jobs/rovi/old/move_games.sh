#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# This ensures that the script will stop if any command fails, preventing
# inconsistent states.
set -e

# Define variables for paths and ownership for better readability and maintainability.
SOURCE_DIR="/tmp/release"
DEST_DIR="/catalog/release"
OWNER="uploadr"
GROUP="uploadr"

echo "Starting release process for games..."

# Step 1: Ensure the source directory exists before attempting operations on it.
# This prevents errors if the staging directory is not present.
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist. Aborting."
    exit 1
fi

# Step 2: Change ownership of the source directory and its contents.
# This ensures that the files have the correct ownership ('uploadr.uploadr')
# before they are copied to the final destination. The 'cp -p' command
# will then attempt to preserve this ownership at the destination.
echo "Changing ownership of '$SOURCE_DIR' to '$OWNER:$GROUP' recursively..."
chown -R "$OWNER:$GROUP" "$SOURCE_DIR"
echo "Ownership changed successfully."

# Step 3: Copy files from the temporary staging area to the final catalog.
# -r: recursive copy for directories and their contents.
# -f: force overwrite existing files at the destination without prompt.
# -p: preserve file attributes (mode, ownership, timestamps) from source to destination.
# -v: verbose output, showing files as they are copied.
echo "Copying files from '$SOURCE_DIR' to '$DEST_DIR'..."
cp -rfpv "$SOURCE_DIR"/* "$DEST_DIR"
echo "Files copied successfully."

# Step 4: Clean up the temporary source directory.
# This removes the staging directory and its contents after a successful copy.
echo "Removing temporary source directory '$SOURCE_DIR'..."
rm -rf "$SOURCE_DIR"
echo "Temporary directory removed."

echo "Release process completed successfully."
