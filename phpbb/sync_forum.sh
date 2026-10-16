#!/usr/bin/env bash

# Check if a filename/filepath was provided
if [ -z "$1" ]; then
    echo "Error: No file specified."
    echo "Usage: $0 <file_path>"
    exit 1
fi

FILE_PATH="$1"

# Execute rsync for the specified file
rsync --progress -h -avpre ssh "$FILE_PATH" "lanik:~/public_html/forums/$FILE_PATH"
