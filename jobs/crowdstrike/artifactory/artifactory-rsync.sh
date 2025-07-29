#!/usr/bin/env bash

# Define common source and destination base paths
SOURCE_BASE_PATH="$HOME/BitBucket/TechOpsCICD/govcloud-jfrog-k8s-stack"
DEST_BASE_PATH="$HOME/BitBucket/GovCloud"
RSYNC_OPTIONS=(-avpr --exclude 'secrets*')

# Function to perform rsync for a given environment
sync_environment() {
    local env_name=$1
    echo && echo "Syncing $env_name..."
    
    # Sync clusters
    if ! rsync "${RSYNC_OPTIONS[@]}" "$SOURCE_BASE_PATH/clusters/" "$DEST_BASE_PATH/$env_name/govcloud-jfrog-k8s-stack/clusters/"; then
        echo "Error: rsync failed for $env_name clusters."
        exit 1
    fi

    # Sync services
    if ! rsync "${RSYNC_OPTIONS[@]}" "$SOURCE_BASE_PATH/services/" "$DEST_BASE_PATH/$env_name/govcloud-jfrog-k8s-stack/services/"; then
        echo "Error: rsync failed for $env_name services."
        exit 1
    fi
    echo "$env_name sync complete."
}

# Perform sync for Eagle environment
sync_environment "Eagle"

# Perform sync for Merlin environment
sync_environment "Merlin"

echo && echo "All rsync operations completed successfully."
