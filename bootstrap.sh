#!/bin/bash

DIR='/raptoreum/.raptoreumcore'
POWCAHCE_FILE='https://bootstrap.raptoreum.com/powcaches/powcache.dat'

if [ ! -d $DIR ]; then
  mkdir -p $DIR
  cd $DIR
  if [[ "$BOOTSTRAP" =~ (^.+)\.tar\.xz$ ]]; then
    wget -O bootstrap.tar.xz $BOOTSTRAP
    tar -xvf bootstrap.tar.xz
    rm bootstrap.tar.xz
  elif [[ "$BOOTSTRAP" =~ (^.+)\.zip$ ]]; then
    wget -O bootstrap.zip $BOOTSTRAP
    unzip -q bootstrap.zip
    rm bootstrap.zip
  else
    wget $POWCAHCE_FILE
  fi
else
  echo "Datadir has been detected so bootstrap will not be used..."
fi
