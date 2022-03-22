#!/bin/bash

/usr/bin/mysqld_safe > /dev/null 2>&1 &

RET=1

while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MySQL service startup" ; sleep 5
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
done

PASS=${MYSQL_ADMIN_PASS:-$(pwgen -s 12 1)}

mysql -uroot -e "CREATE USER 'admin'@'%' IDENTIFIED BY '$PASS'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION"

CREATE_MYSQL_USER=false

if [ -n "$MYSQL_OPTIONAL_USER" ] || [ -n "$MYSQL_USER_NAME" ] || [ -n "$MYSQL_USER_DB" ] || [ -n "$MYSQL_USER_PASS" ]; then
    CREATE_MYSQL_USER=true
fi

if [ "$CREATE_MYSQL_USER" = true ]; then
    _user=${MYSQL_USER_NAME:-user}
    _db=${MYSQL_USER_DB:-db}
    _pass=${MYSQL_USER_PASS:-passw0rd}
    mysql -uroot -e "CREATE USER '${_user}'@'%' IDENTIFIED BY  '${_pass}'"
    mysql -uroot -e "GRANT USAGE ON *.* TO  '${_user}'@'%' IDENTIFIED BY '${_pass}'"
    mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${_db}"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON ${_db}.* TO '${_user}'@'%'"
fi

echo "=> Done!"
echo
echo "==========================================================="
echo
echo "  MySQL is now running. You can connect as administrator:  "
echo
echo "    user: admin                                            "
echo "    password: $PASS                                        "
echo
echo "==========================================================="
echo

mysqladmin -uroot shutdown
