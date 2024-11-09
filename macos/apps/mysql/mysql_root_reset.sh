#!/usr/bin/env bash
set -eu
sudo -v

echoerr() { echo "$@" 1>&2; }

if mysqladmin ping --silent; then
  echoerr "Please ensure MySQL is stopped."
  exit 1
fi

echoerr "Start MySQL with --skip-grant-tables"
sudo mysqld_safe --skip-grant-tables &
while ! mysqladmin ping --silent; do
  sleep 0.1
done
echoerr "MySQL started."

echoerr "Execute SQL commands to reset root password and SHUTDOWN"
mysql -u root <<EOF
FLUSH PRIVILEGES;
UPDATE mysql.user SET authentication_string=null WHERE User='root';
FLUSH PRIVILEGES;
EOF

NEW_PASSWORD="root"
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$NEW_PASSWORD';
FLUSH PRIVILEGES;
SHUTDOWN
EOF

while mysqladmin ping --silent; do
  sleep 0.1
done

echoerr "Done. You may start MySQL normally."
