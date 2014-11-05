FROM base/devel:latest
MAINTAINER l3iggs <l3iggs@live.com>

# setup the generic build environment
RUN pacman -Suy --noconfirm
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
WORKDIR /root/OpenNote/OpenNote
RUN grunt
