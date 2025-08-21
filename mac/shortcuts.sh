#!/usr/bin/env bash
# This script will create my shortcuts in home directory

# Exit immediately if a command exits with a non-zero status.
set -e

if [[ $PWD != "$HOME" ]]; then
  echo "Changing directory to $HOME..."
  cd "$HOME"
fi

SOURCE_DIR="$HOME/GitLab/Lanik/mac-shell"

echo "Processing common shortcuts..."
find "$SOURCE_DIR" -maxdepth 1 -type l ! -iname "*mac*" -print0 | while IFS= read -r -d $'\0' link_path; do
  link_name=$(basename "$link_path")
  echo "  Creating shortcut for $link_name"
  rm -f "$link_name" # Use -f for force removal, -r is for directories
  ln -sf "Shell/$link_name" "$link_name"
done

echo "Processing Mac-Only shortcuts..."
find "$SOURCE_DIR" -maxdepth 1 -type l -iname "*mac*" -print0 | while IFS= read -r -d $'\0' link_path; do
  link_name=$(basename "$link_path")
  echo "  Creating shortcut for $link_name"
  rm -f "$link_name"
  ln -sf "Shell/mac/$link_name" "$link_name"
done

echo "Bob's your Uncle! "
