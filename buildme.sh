#!/bin/bash

git submodule update --init

docker build .
