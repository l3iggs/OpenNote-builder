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
RUN rm -rf /root/package-query

ADD https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz /root/
RUN tar -vxf /root/yaourt.tar.gz -C /root/
RUN cd /root/yaourt && makepkg -s --noconfirm --asroot
RUN pacman -U --noconfirm --needed /root/yaourt/*.pkg.tar.xz
RUN rm -rf /root/yaourt

# git
RUN pacman -Suy --noconfirm --needed git
RUN git config --global user.email "buildbot@none.com"
RUN git config --global user.name "Build Bot"


# Build deps
RUN pacman -Suy --noconfirm nodejs unzip
RUN yaourt -Suya --noconfirm nodejs-bower nodejs-grunt-cli

# get source code
ADD https://github.com/FoxUSA/OpenNote/archive/master.zip /root/
RUN unzip /root/master.zip -d /root/
RUN rm /root/master.zip
ADD https://github.com/FoxUSA/OpenNoteService-PHP/archive/master.zip /root/
RUN unzip /root/master.zip -d /root/
RUN rm /root/master.zip

# Build
WORKDIR /root/OpenNote-master/
RUN npm install
RUN sed -i 's/"bower install"/"bower --allow-root install"/g' Gruntfile.js
RUN grunt

# Install runtime deps
RUN pacman -Suy --noconfirm --needed apache php php-apache mariadb pwgen

# setup mysql
#RUN su mysql -c "mysqld"
#RUN su mysql -c "mysqld-post"


# setup apache with php and mysql enabled
#RUN sed -i 's,#LoadModule ssl_module modules/mod_ssl.so,LoadModule ssl_module modules/mod_ssl.so\nLoadModule php5_module modules/libphp5.so,g' /etc/httpd/conf/httpd.conf
#RUN sed -i 's,LoadModule mpm_event_module modules/mod_mpm_event.so,LoadModule mpm_prefork_module modules/mod_mpm_prefork.so,g' /etc/httpd/conf/httpd.conf
#RUN sed -i 's,;extension=pdo_mysql.so,extension=pdo_mysql.so' /etc/php/php.ini



#RUN apachectl start
