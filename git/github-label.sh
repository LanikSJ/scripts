#!/bin/bash

# Description: Ensures all specified GitHub repositories under LanikSJ have the specified label
#              or removes it from all repositories (use --delete flag)
# Usage: ./github-label.sh <label> [description] [--delete]

repos=(
    "AdmiraList"
    "android-messages-desktop"
    "awscli-aliases"
    "dfimage"
    "docker-php-alpine"
    "docker-web-service"
    "dotfiles"
    "homebrew-bump-cask"
    "homebrew-tap"
    "laniksj"
    "laniksj.github.io"
    "lsusb"
    "scripts"
    "ubo-filters"
    "webannoyances"
    "zsh-theme"
)

# Parse arguments
LABEL="$1"
DESCRIPTION="$2"
DELETE_MODE=false

if [[ "$1" == "--delete" ]]; then
    LABEL="$2"
    DESCRIPTION="$3"
    DELETE_MODE=true
elif [[ "$2" == "--delete" ]]; then
    DELETE_MODE=true
    DESCRIPTION=""
elif [[ "$3" == "--delete" ]]; then
    DELETE_MODE=true
fi

# Validate label
if [[ -z "$LABEL" || "$LABEL" == "--delete" ]]; then
    echo "Error: Label name is required"
    echo "Usage: ./github-label.sh <label> [description] [--delete]"
    exit 1
fi

for repo in "${repos[@]}"; do
    echo "🔍 Checking Repository LanikSJ/$repo"
    if gh label list --repo LanikSJ/"$repo" | grep -q "^${LABEL}"; then
        if [[ "$DELETE_MODE" == true ]]; then
            echo "🗑️ Removing Label '$LABEL' from LanikSJ/$repo"
            gh label delete --repo LanikSJ/"$repo" "$LABEL" --yes
        else
            echo "✅ Label '$LABEL' Already Exists in LanikSJ/$repo"
        fi
    else
        if [[ "$DELETE_MODE" == true ]]; then
            echo "ℹ️ Label '$LABEL' Not Found in LanikSJ/$repo"
        else
            echo "⚙️ Creating Label '$LABEL' in LanikSJ/$repo"
            if [[ -n "$DESCRIPTION" ]]; then
                gh label create --repo LanikSJ/"$repo" "$LABEL" --description "$DESCRIPTION"
            else
                gh label create --repo LanikSJ/"$repo" "$LABEL"
            fi
        fi
    fi
done
