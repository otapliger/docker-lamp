FROM phusion/baseimage:bionic-1.0.0
MAINTAINER Otavio Pliger <docker@otaviopliger.com>
ENV REFRESHED_AT 2022-03-22

# based on dgraziotin/lamp
# MAINTAINER Daniel Graziotin <daniel@ineed.coffee>

ENV DOCKER_USER_ID 501 
ENV DOCKER_USER_GID 20
ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50

# tweaks to give Apache/PHP write permissions to the app
RUN usermod -u ${BOOT2DOCKER_ID} www-data && \
usermod -G staff www-data && \
useradd -r mysql && \
usermod -G staff mysql
RUN groupmod -g $(($BOOT2DOCKER_GID + 10000)) $(getent group $BOOT2DOCKER_GID | cut -d: -f1)
RUN groupmod -g ${BOOT2DOCKER_GID} staff

# install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
apt-get -y install apache2 curl git libapache2-mod-php mysql-server php-apcu php-curl php-gd php-mbstring php-mysql php-xdebug php-xml php-zip postfix pwgen python3-setuptools unzip wget zip && \
echo "ServerName localhost" >> /etc/apache2/apache2.conf

# install supervisor
RUN curl -L https://pypi.io/packages/source/s/supervisor/supervisor-4.2.2.tar.gz | tar xvz && \
mv supervisor-4.2.2 supervisor && \
cd supervisor && \
python3 setup.py install

# add image configuration and scripts
ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf
ADD supervisord.conf /etc/supervisor/supervisord.conf

# remove pre-installed database
RUN rm -rf /var/lib/mysql

# add MySQL utils
ADD create_mysql_users.sh /create_mysql_users.sh
RUN chmod 755 /*.sh

# add phpMyAdmin
RUN wget -O /tmp/phpmyadmin.tar.gz https://files.phpmyadmin.net/phpMyAdmin/5.1.3/phpMyAdmin-5.1.3-all-languages.tar.gz
RUN tar xfvz /tmp/phpmyadmin.tar.gz -C /var/www
RUN ln -s /var/www/phpMyAdmin-5.1.3-all-languages /var/www/phpmyadmin
RUN mv /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config.inc.php

# config to enable .htaccess
ADD apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# configure /app folder with sample app
RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html
ADD app/ /app

# environment variables to configure MySQL
ENV MYSQL_PASS:-$(pwgen -s 12 1)

# environment variables to configure PHP
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

# add volumes for the app and MySQL
VOLUME  ["/etc/mysql", "/var/lib/mysql", "/app" ]

EXPOSE 80 3306
CMD ["/run.sh"]
