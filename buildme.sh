#!/bin/bash

function getcode {
#$1 = repo name
#$2 = repo url
  if cd $1; then
    git pull
  else
    git clone $2
  fi
} 

getcode OpenNote https://github.com/FoxUSA/OpenNote.git
getcode OpenNoteService-PHP https://github.com/FoxUSA/OpenNoteService-PHP.git

docker build .
