FROM base/archlinux
MAINTAINER l3iggs <l3iggs@live.com>

# update pacman db
RUN pacman -Suy --noconfirm

# setup yaourt
RUN pacman -Suy --noconfirm --needed base-devel
RUN bash -c 'bash <(curl aur.sh) -si --noconfirm --asroot package-query yaourt'
RUN yaourt -Suya

# git
RUN pacman -Suy --noconfirm --needed git
RUN git config --global user.email "buildbot@none.com"
RUN git config --global user.name "Build Bot"

# Install some LAMP stack things
RUN pacman -Suy --noconfirm --needed apache php php-apache mariadb openssl
RUN pacman -Suy --noconfirm --needed sqlite php-sqlite

# setup apache ssl
RUN sed -i 's,#LoadModule ssl_module modules/mod_ssl.so,LoadModule ssl_module modules/mod_ssl.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so,LoadModule socache_shmcb_module modules/mod_socache_shmcb.so,g' /etc/httpd/conf/httpd.conf
#RUN sed -i 's,#Include conf/extra/httpd-ssl.conf,Include conf/extra/httpd-ssl.conf,g' /etc/httpd/conf/httpd.conf

# setup php
RUN sed -i 's,LoadModule rewrite_module modules/mod_rewrite.so,LoadModule rewrite_module modules/mod_rewrite.so\nLoadModule php5_module modules/libphp5.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,LoadModule mpm_event_module modules/mod_mpm_event.so,LoadModule mpm_prefork_module modules/mod_mpm_prefork.so,g' /etc/httpd/conf/httpd.conf
RUN echo "Include conf/extra/php5_module.conf" >> /etc/httpd/conf/httpd.conf

RUN sed -i 's,;extension=pdo_mysql.so,extension=pdo_mysql.so,g' /etc/php/php.ini
#RUN sed -i 's,;extension=mysqli.so,extension=mysqli.so,g' /etc/php/php.ini
RUN sed -i 's,mysql.trace_mode = Off,mysql.trace_mode = On,g' /etc/php/php.ini
RUN sed -i 's,mysql.default_host =,mysql.default_host = localhost,g' /etc/php/php.ini
RUN sed -i 's,mysql.default_user =,mysql.default_user = root,g' /etc/php/php.ini
RUN sed -i 's,mysql.default_password =,mysql.default_password = tacobell,g' /etc/php/php.ini

RUN sed -i 's,;extension=openssl.so,extension=openssl.so,g' /etc/php/php.ini

RUN sed -i 's,;extension=sqlite3.so,extension=sqlite3.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=pdo_sqlite.so,extension=pdo_sqlite.so,g' /etc/php/php.ini

# setup deps
RUN pacman -Suy --noconfirm --needed zip unzip dos2unix vim

# Build deps
RUN pacman -Suy --noconfirm --needed nodejs
RUN yaourt -Suya --noconfirm --needed nodejs-bower nodejs-grunt-cli php-composer

# get source code
ADD OpenNote /root/OpenNote
#RUN cd /root/OpenNote; git checkout 14.07.02
ADD OpenNoteService-PHP /root/OpenNoteService-PHP
#RUN cd /root/OpenNoteService-PHP; git checkout 14.07.01

# Compose OpenNoteService
RUN cd /root/OpenNoteService-PHP && composer install

# move over files from service repo
RUN mv /root/OpenNoteService-PHP/* /root/OpenNote/OpenNote/.

# Build OpenNote
RUN cd /root/OpenNote && npm install
RUN sed -i 's/"bower install"/"bower --allow-root install"/g' /root/OpenNote/Gruntfile.js
RUN cd /root/OpenNote && grunt build

# the build is now done. package it up
RUN rm -rf /root/OpenNote/OpenNote/.gitignore
RUN rm -rf /root/OpenNote/OpenNote/.project
RUN rm -rf /root/OpenNote/OpenNote/Doc
RUN rm -rf /root/OpenNote/OpenNote/License.txt
RUN rm -rf /root/OpenNote/OpenNote/README.md
RUN rm -rf /root/OpenNote/OpenNote/Service.test
RUN rm -rf /root/OpenNote/OpenNote/composer*
RUN cd /root/OpenNote/OpenNote/; zip -r /OpenNote.zip .

# extract opennote package
RUN mkdir /app
#ADD https://github.com/FoxUSA/OpenNote/releases/download/14.07.02/OpenNote.zip /
RUN unzip /OpenNote.zip -d /app/

# Clean up
#RUN rm /app/Service/Config.template
#RUN rm /app/Service/install.php

# Add pre-made config and setup script
#ADD Config.php /app/Service/

# mysql setup script
#RUN pacman -Suy --noconfirm --needed pwgen
#ADD create_mysql_admin_user.sh /root/create_mysql_admin_user.sh
#RUN chmod +x /root/create_mysql_admin_user.sh
#ENV MYSQL_PASS tacobell

# sqlite setup
RUN sed -i 's,//return self::sqliteConfig();,return self::sqliteConfig();,g' /app/Service/Config.php
RUN sed -i 's,return self::mysqlConfig();,//return self::mysqlConfig();,g' /app/Service/Config.php
RUN sed -i 's,//return self::sqliteConfig();,return self::sqliteConfig();,g' /app/Service/Config.template
RUN sed -i 's,sqlite:%s\%s,sqlite:%s/%s,g' /app/Service/Config.template

# Set permissions
RUN chmod 755 /app -R
RUN chown http:http /app -R

# setup mysql populate database
#WORKDIR /usr
#RUN mysql_install_db --user=mysql --ldata=/var/lib/mysql
#RUN cd '.' ; ./bin/mysqld_safe --datadir='/var/lib/mysql' & sleep 5
#RUN mysql -u root -e "CREATE DATABASE OpenNote"
#RUN mysql -u root OpenNote < /app/Service/model/sql/notebook.sql
#RUN mysql_waitpid $(cat /var/lib/mysql/*.pid) 10

#RUN /root/create_mysql_admin_user.sh

# move app to served directory
RUN mv /app/* /srv/http/.

# start mysql and apache servers
CMD cd '.' ; ./bin/mysqld_safe --datadir='/var/lib/mysql'; apachectl -DFOREGROUND
