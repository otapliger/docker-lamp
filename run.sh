#!/bin/bash

VOLUME_HOME="/var/lib/mysql"

sed -ri -e "s/^upload_max_filesize.*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" -e "s/^post_max_size.*/post_max_size = ${PHP_POST_MAX_SIZE}/" /etc/php/7.2/apache2/php.ini

sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=staff/" /etc/apache2/envvars

if [ -n "$APACHE_ROOT" ];then
    rm -f /var/www/html && ln -s "/app/${APACHE_ROOT}" /var/www/html
fi

mkdir -p /var/run/mysqld

sed -i -e "s/cfg\['blowfish_secret'\] = ''/cfg['blowfish_secret'] = '`date | md5sum`'/" /var/www/phpmyadmin/config.inc.php
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s/user.*/user = www-data/" /etc/mysql/mysql.conf.d/mysqld.cnf

chown -R www-data:staff /app
chown -R www-data:staff /var/www
chown -R www-data:staff /var/lib/mysql
chown -R www-data:staff /var/log/mysql
chown -R www-data:staff /var/run/mysqld
chmod -R 770 /var/lib/mysql
chmod -R 770 /var/run/mysqld

if [ -e /var/run/mysqld/mysqld.sock ];then
    rm /var/run/mysqld/mysqld.sock
fi

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    mysqld --initialize-insecure --innodb-flush-log-at-trx-commit=0 --skip-log-bin

    if [ $? -ne 0 ]; then
        mysql_install_db > /dev/null 2>&1
    fi

    /create_mysql_users.sh
else
    echo "=> Using an existing volume of MySQL"
fi

exec supervisord -n
