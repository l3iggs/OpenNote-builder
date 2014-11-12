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
ADD OpenNote /root/
#RUN cd /root/OpenNote; git checkout 14.07.02
ADD OpenNoteService-PHP /root/
#RUN cd /root/OpenNoteService-PHP; git checkout 14.07.01

# Compose OpenNoteService
RUN cd /root/OpenNoteService-PHP && composer install

# move over files from service repo
RUN mv /root/OpenNoteService-PHP/* /root/OpenNote/OpenNote/.

# Build OpenNote
RUN cd /root/OpenNote && npm install
RUN sed -i 's/"bower install"/"bower --allow-root install"/g' /root/OpenNote/Gruntfile.js
RUN cd /root/OpenNote && grunt

# the build is done. package it up now
#RUN rm -rf /root/OpenNote/
RUN cd /root/OpenNote/OpenNote/; zip -r /OpenNote.zip .

# extract opennote
RUN mkdir /app
RUN unzip /OpenNote.zip /app/

# Install runtime deps
RUN pacman -Suy --noconfirm --needed apache php php-apache mariadb

# setup mysql
RUN pacman -Suy --noconfirm --needed pwgen
ADD create_mysql_admin_user.sh /root/create_mysql_admin_user.sh
RUN chmod +x /root/create_mysql_admin_user.sh
ENV MYSQL_PASS tacobell
RUN /root/create_mysql_admin_user.sh

# setup apache with ssl, php and mysql enabled
RUN sed -i 's,#LoadModule ssl_module modules/mod_ssl.so,LoadModule ssl_module modules/mod_ssl.so\nLoadModule php5_module modules/libphp5.so,g' /etc/httpd/conf/httpd.conf
RUN sed -i 's,LoadModule mpm_event_module modules/mod_mpm_event.so,LoadModule mpm_prefork_module modules/mod_mpm_prefork.so,g' /etc/httpd/conf/httpd.conf
RUN echo "Include conf/extra/php5_module.conf" >> /etc/httpd/conf/httpd.conf
RUN sed -i 's,;extension=pdo_mysql.so,extension=pdo_mysql.so,g' /etc/php/php.ini
RUN rm /app/Service/Config.template
RUN rm /app/Service/install.php
ADD Config.php /app/Service/Config.php
RUN mv /app /srv/http/notes
RUN sudo chown -R http:http /srv/http
RUN chmod -R 755 /srv/http

CMD mysqld_safe & apachectl start

#CMD while true; sleep 2; done
