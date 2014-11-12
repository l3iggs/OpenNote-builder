OpenNote-builder
================

dockerfile to build (from the latest git) then run an OpenNote server

Usage:
```bash
git clone https://github.com/l3iggs/OpenNote-builder.git
cd OpenNote-builder
git pull; git submodule update --init; docker build -t opennote .
```

Requires docker and git.
