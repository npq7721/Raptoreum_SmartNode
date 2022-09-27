#!/bin/bash

EXECUTABLE='raptoreumd'
DIR='/raptoreum/.raptoreumcore'
CONF_FILE='raptoreum.conf'
FILE=$DIR/$CONF_FILE

graceful_shutdown() {
  echo "Container is shutting down. gracefully shutting down raptoreum core daemon"
  raptoreum-cli --conf=$FILE stop
  sleep 30s
  killall -q -w -s SIGINT raptoreumd
  # Check for any core files
  CoreCount=$(find . -name core | wc -l)
  if [ $CoreCount != 0 ] ; then
     echo "Core file: ${CoreFile} - generating stacktrace"
     CoreFile=$(find . -name core -print -quit)
     CURRENT_DATE = `date +%s`
     cp $CoreFile /raptoreum/.raptoreumcore/core_${CURRENT_DATE}
  else
    echo "raptoreum core shutdown successfully"
  fi

  kill -TERM "$child" 2>/dev/null
}


if [[ "$FORCE_BOOTSTRAP" == "true" ]]; then
  if [ -d $DIR ]; then
    rm -rf $DIR
  fi
fi

if [ -n "$CONF" ]; then
  if [ -e "$FILE" ]; then
    rm $FILE
  fi
fi

# Create directory and config file if it does not exist yet
if [ ! -e "$FILE" ]; then
  bootstrap.sh
  if [ -n "$CONF" ]; then
    echo "${CONF}" >> $FILE
  fi
fi

if [ -n "$OPEN_FILE_LIMIT" ]; then
  OPEN_FILE_LIMIT=65000
fi

ulimit -c unlimited
ulimit -n $OPEN_FILE_LIMIT

trap graceful_shutdown 1 2 3 4 5 6 9 15
$EXECUTABLE -datadir=$DIR -conf=$FILE &
child=$!
echo "waiting for process $child to be killed"
wait $child