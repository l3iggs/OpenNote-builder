FROM base/archlinux
MAINTAINER l3iggs <l3iggs@live.com>

# update
RUN pacman -Suy --noconfirm

# setup yaourt
RUN pacman -Suy --noconfirm --needed base-devel
ADD https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz /root/
RUN tar -vxf /root/package-query.tar.gz -C /root/
RUN cd /root/package-query && makepkg -s --noconfirm --asroot
RUN pacman -U --noconfirm --needed /root/package-query/*.pkg.tar.xz
RUN rm -rf /root/package-query*

ADD https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz /root/
RUN tar -vxf /root/yaourt.tar.gz -C /root/
RUN cd /root/yaourt && makepkg -s --noconfirm --asroot
RUN pacman -U --noconfirm --needed /root/yaourt/*.pkg.tar.xz
RUN rm -rf /root/yaourt*

# git
RUN pacman -Suy --noconfirm --needed git
RUN git config --global user.email "buildbot@none.com"
RUN git config --global user.name "Build Bot"

# setup deps
RUN pacman -Suy --noconfirm --needed zip unzip

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

# Install runtime deps
RUN pacman -Suy --noconfirm --needed apache php php-apache mariadb openssl

# setup apache ssl, php and mysql enabled
RUN sed -i 's,#LoadModule ssl_module modules/mod_ssl.so,LoadModule ssl_module modules/mod_ssl.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so,LoadModule socache_shmcb_module modules/mod_socache_shmcb.so,g' /etc/httpd/conf/httpd.conf
#RUN sed -i 's,#Include conf/extra/httpd-ssl.conf,Include conf/extra/httpd-ssl.conf,g' /etc/httpd/conf/httpd.conf

RUN sed -i 's,LoadModule rewrite_module modules/mod_rewrite.so,LoadModule rewrite_module modules/mod_rewrite.so\nLoadModule php5_module modules/libphp5.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,LoadModule mpm_event_module modules/mod_mpm_event.so,LoadModule mpm_prefork_module modules/mod_mpm_prefork.so,g' /etc/httpd/conf/httpd.conf
RUN echo "Include conf/extra/php5_module.conf" >> /etc/httpd/conf/httpd.conf

RUN sed -i 's,;extension=pdo_mysql.so,extension=pdo_mysql.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=mysqli.so,extension=mysqli.so,g' /etc/php/php.ini

# extract opennote package
RUN mkdir /app
RUN rm /OpenNote.zip
ADD https://github.com/FoxUSA/OpenNote/releases/download/14.07.02/OpenNote.zip /
RUN unzip /OpenNote.zip -d /app/

# Clean up
RUN rm /app/Service/Config.*
RUN rm /app/Service/install.php

# Add pre-made config and setup script
ADD Config.php /app/Service/

# mysql setup script
RUN pacman -Suy --noconfirm --needed pwgen
ADD create_mysql_admin_user.sh /root/create_mysql_admin_user.sh
RUN chmod +x /root/create_mysql_admin_user.sh
#ENV MYSQL_PASS tacobell

# Set permissions
RUN chmod 755 /app -R
RUN chown http:http /app -R

# setup mysql populate database
WORKDIR /usr
#RUN mysql_install_db --user=mysql --ldata=/var/lib/mysql
#RUN cd '.' ; ./bin/mysqld_safe --datadir='/var/lib/mysql' & sleep 2
#RUN mysql -u root -e "CREATE DATABASE OpenNote"
#RUN mysql -u root OpenNote < /app/Service/model/sql/notebook.sql
#RUN mysql_waitpid $(cat /var/lib/mysql/*.pid) 10

#RUN /root/create_mysql_admin_user.sh

# move app to served directory
RUN mv /app /srv/http/notes

# start mysql and apache servers
CMD apachectl start; cd '.' ; ./bin/mysqld_safe --datadir='/var/lib/mysql'
