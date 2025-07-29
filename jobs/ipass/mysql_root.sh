#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

# Ensure the temporary file is removed even if the script exits prematurely
trap "rm -f /tmp/mysql_root" EXIT

echo "Attempting to stop MySQL gracefully..."
if ! service mysqld stop; then
    echo "Graceful stop failed, attempting to forcefully kill mysqld processes..."
    pkill -9 mysqld || true # Use || true to prevent script from exiting if no processes are found
fi

echo "Creating MySQL root reset script! "
cat > /tmp/mysql_root <<EOF-mysql
UPDATE mysql.user SET Password=PASSWORD('blu3H@tT0p') WHERE User='root';
FLUSH PRIVILEGES;
EOF-mysql

echo "Starting MySQL in safe mode for password reset..."
# Start mysqld_safe in the background and capture its PID
mysqld_safe --skip-grant-tables &
MYSQLD_SAFE_PID=$! # Get the PID of the last background command

# Wait a moment for MySQL to start
sleep 5

echo "Running MySQL Script... "
mysql < /tmp/mysql_root

echo "Stopping MySQL safe mode instance..."
# Kill the specific mysqld_safe process
kill -9 $MYSQLD_SAFE_PID || true # Use || true in case process already died

# Ensure all mysqld processes are gone before starting normally
echo "Ensuring all mysqld processes are terminated..."
pkill -9 mysqld || true

echo "Starting MySQL normally..."
service mysqld start

echo "MySQL root password reset complete and service restarted."
