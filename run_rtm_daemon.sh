#!/bin/bash
EXECUTABLE='raptoreumd'
DIR='/raptoreum/.raptoreumcore'
CONF_FILE='raptoreum.conf'
FILE=$DIR/$CONF_FILE
LOGS_DIR=/raptoreum/logs/
CORE_DIR=/raptoreum/corefiles/

function maybe_bootstrap() {
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
}

mkdir -p $LOGS_DIR
mkdir -p $CORE_DIR

exit_code=1
while [[ $exit_code -ne 0 ]];
do
  start_time=$(date +%s)
  echo "starting raptoreum daemon"
  $EXECUTABLE -datadir=$DIR -conf=$FILE
  exit_code=$?
  echo "raptoreum terminate with exit code $exit_code"
  end_time=$(date +%s)
  run_time=$((end_time-start_time))
  if (( run_time < 60 && exit_code > 0)); then
    cp ${DIR}/debug.log ${LOGS_DIR}debug_$(date +%s).log
    rm -rf $DIR
    maybe_bootstrap
  fi
  if (( exit_code > 0 )); then
    sleep 60s
    killall -q -w -s 9 -r raptoreum
  fi
done