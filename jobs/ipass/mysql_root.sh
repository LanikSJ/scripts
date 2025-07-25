#!/bin/bash

service mysqld stop
pkill -9 mysqld
echo "Creating MySQL root reset script! "
cat > /tmp/mysql_root <<EOF-mysql
UPDATE mysql.user SET Password=PASSWORD('blu3H@tT0p') WHERE User='root';
FLUSH PRIVILEGES;
EOF-mysql
echo "Starting MySQL..."
mysqld_safe --skip-grant-tables &
echo "Running MySQL Script... "
mysql < /tmp/mysql_root
echo "Killing MySQL! "
pkill -9 mysqld
echo "Clean up! "
rm -f /tmp/mysql_root
service mysqld start
