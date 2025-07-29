#!/usr/bin/env bash

# Set -e to exit immediately if a command exits with a non-zero status.
set -e

# Get all remote branches, excluding HEAD, and iterate over them.
# The --format='%(refname:short)' gives us 'remote/branch_name'.
# We then filter out any 'HEAD' references.
git for-each-ref --format='%(refname:short)' refs/remotes/ | grep -v '/HEAD$' | while read remote_branch; do
    # Extract remote name and branch name
    # Example: remote_branch="origin/main"
    # branch_name="main"
    branch_name=$(echo "$remote_branch" | cut -d'/' -f2-) # Use f2- to handle branch names with slashes

    # Check if a local branch with the same name already exists
    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Creating tracking branch: $branch_name tracking $remote_branch"
        git branch --track "$branch_name" "$remote_branch"
    else
        echo "Local branch '$branch_name' already exists. Skipping."
    fi
done

echo "Finished creating tracking branches."
