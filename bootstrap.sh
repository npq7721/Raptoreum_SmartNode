#!/bin/bash

DIR='/raptoreum/.raptoreumcore'
#BOOTSTRAP_TAR='https://bootstrap.raptoreum.com/bootstraps_for_v1.3.17.00/bootstrap.tar.xz'
BOOTSTRAP_TAR='https://bootstrap.raptoreum.com/bootstraps_for_v1.3.17.00/bootstrap.zip'
POWCAHCE_FILE='https://bootstrap.raptoreum.com/powcaches/powcache.dat'

if [ ! -d $DIR ]; then
  mkdir -p $DIR
  cd $DIR
  if [[ "$BOOTSTRAP" =~ (^.+)\.tar\.xz$ ]]; then
    wget $BOOTSTRAP
    tar -xvf bootstrap.tar.xz
  elif [[ "$BOOTSTRAP" =~ (^.+)\.zip$ ]]; then
    wget $BOOTSTRAP
    unzip -q bootstrap.zip
  else
    wget $POWCAHCE_FILE
  fi
else
  echo "Datadir has been detected so bootstrap will not be used..."
fi
