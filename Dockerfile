FROM base/devel:latest
MAINTAINER l3iggs <l3iggs@live.com>

# setup the generic build environment
RUN pacman -Suy --noconfirm
RUN git config --global user.email "buildbot@none.com"
RUN git config --global user.name "Build Bot"

# Build deps
RUN pacman -Suy --noconfirm nodejs

