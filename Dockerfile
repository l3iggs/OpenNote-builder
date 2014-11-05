#FROM base/devel:latest
FROM codekoala/arch
MAINTAINER l3iggs <l3iggs@live.com>

# update
RUN pacman -Suy --noconfirm

# setup yaourt
RUN pacman -Suy --noconfirm --needed base-devel
ADD https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz /root/
RUN tar -vxf /root/package-query.tar.gz -C /root/
RUN cd /root/package-query && makepkg -s --noconfirm --asroot
RUN pacman -U --noconfirm /root/package-query/*.pkg.tar.xz
RUN rm -rf /root/package-query

ADD https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz /root/
RUN tar -vxf /root/yaourt.tar.gz -C /root/
RUN cd /root/yaourt && makepkg -s --noconfirm --asroot
RUN pacman -U --noconfirm /root/yaourt/*.pkg.tar.xz
RUN rm -rf /root/yaourt

# git
RUN pacman -Suy --noconfirm git
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
RUN pacman -Suy --noconfirm apache php php-apache mariadb

# Prepare for run
RUN sed -i 's,#LoadModule ssl_module modules/mod_ssl.so,LoadModule ssl_module modules/mod_ssl.so\nLoadModule modules/libphp5.so,g' /etc/httpd/conf/httpd.conf
RUN systemctl restart httpd
