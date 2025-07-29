#!/bin/bash

# Define the MySQL storage directory and the age threshold for old files.
# Files accessed more than OLD_DAYS days ago will be considered for zipping.
MYSQL_STORAGE_DIR="/data/mysql5.0/storage"
OLD_DAYS="+10" # Files older than 10 days

# Define the file types to be zipped
FILE_TYPES=("*.frm" "*.MYD" "*.MYI")

# Temporary file to store the list of files to be zipped
TEMP_FILE=$(mktemp)

echo "Zipping MySQL log files older than ${OLD_DAYS#+} days in ${MYSQL_STORAGE_DIR}..."

# Construct the find command dynamically for better readability and maintainability
FIND_COMMAND="find ${MYSQL_STORAGE_DIR}"
for type in "${FILE_TYPES[@]}"; do
    FIND_COMMAND+=" -name \"${type}\""
done
FIND_COMMAND+=" -type f -atime ${OLD_DAYS} -not -name '*.gz'"

# Execute the find command and store the results in a temporary file
if eval "${FIND_COMMAND}" > "${TEMP_FILE}"; then
    # Check if any files were found
    if [ -s "${TEMP_FILE}" ]; then
        echo "Found files to zip. Compressing now..."
        # Use xargs to handle multiple files and filenames with spaces
        if xargs -r0 gzip < "${TEMP_FILE}"; then
            echo "All done now! MySQL log files have been successfully zipped."
        else
            echo "Error: Failed to zip some files."
            exit 1
        fi
    else
        echo "No MySQL log files older than ${OLD_DAYS#+} days found to zip."
    fi
else
    echo "Error: Failed to execute find command or access directory."
    exit 1
fi

# Clean up the temporary file
rm -f "${TEMP_FILE}"

exit 0
