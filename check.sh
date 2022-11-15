#!/bin/bash
# URLs for raptoreum explorers. Main and backup one.
URL=( 'https://explorer.raptoreum.com/' 'https://explorer.louhintamestarit.fi/' )
URL_ID=0

BOOTSTRAP_TAR=$BOOTSTRAP
HEALTH_LOG=/raptoreum/logs/healthcheck.log
CORE_DIR=/raptoreum/corefiles/

POSE_SCORE=0
PREV_SCORE=0
LOCAL_HEIGHT=0
# Variables provided by cron job enviroment variable.
# They should also be added into .bashrc for user use.
#RAPTOREUM_CLI    -> Path to the raptoreum-cli
#CONFIG_DIR/HOME  -> Path to "$HOME/.raptoreumcore/"

# Add your NODE_PROTX here if you forgot or provided wrong hash during node
# installation.
#NODE_PROTX=

# Prepare some variables that can be set if the user is runing the script
# manually but are set in cron job enviroment.
if [[ -z $RAPTOREUM_CLI ]]; then
  RAPTOREUM_CLI=$(which raptoreum-cli)
fi

if [[ -z $CONFIG_DIR ]]; then
  CONFIG_DIR="/raptoreum/.raptoreumcore/"
fi

function GetNumber () {
  if [[ ${1} =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]]; then
    echo "${1}"
  else
    echo "-1"
  fi
}

function log() {
  echo $@
  echo $@ >> $HEALTH_LOG
}

  function ReadValue () {
    GetNumber "$(cat ${1} 2>/dev/null)"
  }

  # Allow read anything from CLI with $@ arguments. Timeout after 300s.
  function ReadCli () {
    # This should just echo (return) value with standard stdout.
    ${RAPTOREUM_CLI} --conf=/raptoreum/.raptoreumcore/raptoreum.conf $@ &
    PID=$!
    for i in {0..60}; do
      sleep 1
      if ! ps --pid ${PID} 1>/dev/null; then
        # PID ended. Just exit the function.
        #tail -n +2 output.txt
        return
      fi
    done
    # raptoreum-cli did not return after 300s. kill the PID and exit with -1.
    kill -9 $PID
    echo -1
  }

  function forceKillWithCoreFile() {
    killall -q -s SIGABRT -r raptoreum
    sleep 60s
      # Check for any core files
    CoreCount=$(find . -name core | wc -l)
    if [ $CoreCount != 0 ] ; then
       echo "Core file: ${CoreFile} - generating stacktrace"
       CoreFile=$(find . -name core -print -quit)
       CURRENT_DATE=`date +%s`
       cp $CoreFile ${CORE_DIR}core_${CURRENT_DATE}
    fi
    killall -q -w -s 9 -r raptoreum
  }

  function tryToKillDaemonGracefullyFirst() {
    log "$(date -u)  Trying to kill daemon gracefully..."
    killall -r raptoreum
    sleep 30s
    LOCAL_HEIGHT=$(GetNumber "$(ReadCli getblockcount)")
    if (( LOCAL_HEIGHT < 0 )); then
      log  "$(date -u)  Unable to kill daemon gracefully, force kill it..."
      forceKillWithCoreFile
    else
       log "$(date -u) Daemon has restarted..."
    fi
  }
  function tryTiKillAndGetCoreFile() {
    LOCAL_HEIGHT=$(GetNumber "$(ReadCli getblockcount)")
    if (( LOCAL_HEIGHT < 0 )); then
      log  "$(date -u)  It seem to be hang, kill -6"
      forceKillWithCoreFile
    else
       log "$(date -u) Daemon not hang"
    fi
  }

  function CheckPoSe () {
    # Check if the Node PoSe score is changing.
    if [[ -n ${PROTX_HASH} ]]; then
      smartnode_status="$(ReadCli smartnode status)"
      if [[ "$smartnode_status" == "-1" ]]; then
        log "Daemon take too long to response to get smartnode status. it may be hanging."
        tryToKillDaemonGracefullyFirst
        return 1
      else
        protx_hash=$(echo $smartnode_status | jq -r ".proTxHash")
        if [[ "$protx_hash" == "$PROTX_HASH" ]]; then
          pose_score=$(echo $smartnode_status | jq -r ".dmnState.PoSePenalty")
          state=$(echo $smartnode_status | jq -r ".state")
          pose_ban_height=$(echo $smartnode_status | jq -r ".dmnState.PoSeBanHeight")
          ip=$(echo $smartnode_status | jq -r ".dmnState.service")
          if (( $pose_ban_height > 0 )); then
            log "Node currently PoSe banned at height $pose_ban_height. execute the following command on ur core wallet: protx update_service \"$PROTX_HASH\" \"$ip\" \"this node bls private key\"."
            return 1
          fi
          log
          if (( pose_score > 0 )); then
            prev_score=$(ReadValue "/tmp/pose_score")
            echo "${pose_score}" >/tmp/pose_score
            if (( pose_score > prev_score )); then
              log "Pose score is increasing check ur node ASAP."
              return 1
            fi
            log "Node got penalize recently and current pose score is $pose_score and decreasing. please check to make sure node working properly."
            return 0
          fi
          if [[ "$state" == "READY" ]]; then
            log "Node is READY."
            return 0;
          fi
        else
          log "Protx hash of this node is $protx_hash not matching with PROTX_HASH=$PROTX_HASH. please check PROTX_HASH value"
          return 1
        fi
      fi
    fi
    return 0
  }

  function networkHeight() {
    NETWORK_HEIGHT=$(GetNumber $(curl -s "${URL[$URL_ID]}api/getblockcount"))
    if (( NETWORK_HEIGHT < 0 )); then
      URL_ID=$(( (URL_ID + 1) % 2 ))
      NETWORK_HEIGHT=$(GetNumber $(curl -s "${URL[$URL_ID]}api/getblockcount"))
    fi
    echo "$NETWORK_HEIGHT"
  }

  function CheckBlockHeight () {
    # Check local block height.
    block_chain_info="$(ReadCli getblockchaininfo)"
    if [[ $block_chain_info == *"HTTP error"* ]]; then
      log "$(date -u) daemon return error ${blockchaininfo}. some raptoreum process maybe hanging"
      killall -s 9 -r raptoreum
      return 1
    fi
    if [[ "$block_chain_info" == "-1" ]]; then
      log "$(date -u) daemon take too long to response to get blockchaininfo. it may be hanging."
      tryToKillDaemonGracefullyFirst
      return 1
    elif [[ $block_chain_info == *"Could not connect to the server"* ]]; then
      log "$(date -u) daemon may be down. getblockchaininfo error message: $block_chain_info"
      return 1
    else
      block_height=$(echo $block_chain_info | jq -r ".blocks")
      headers=$(echo $block_chain_info | jq -r ".blocks")
      prev_height=$(ReadValue "/tmp/height")
      prev_headers=$(ReadValue "/tmp/headers")
      network_height=$(networkHeight)
      echo "$block_height" > /tmp/height
      echo "$headers" > /tmp/headers
      log -n "$(date -u)  Node height (${block_height}/${network_height})."
      if [[ $((network_height - block_height)) -gt 3 || "$network_height" == "-1" ]]; then
        if (( block_height > prev_height )); then
          log " Increased from ${prev_height} -> ${block_height}, headers from ${prev_headers} -> ${headers}. Node may be syncing so wait..."
        elif (( block_height < prev_height )); then
          log "It may just got rebootstrapping. wait"
        elif [[ "$network_height" != "-1" ]]; then
          if (( headers > prev_headers )); then
            log "Node is syncing."
            return 1;
          fi
          log "node may be stuck."
          tryToKillDaemonGracefullyFirst
          return 1
        else
          log "Daemon seem ok."
        fi
      else
        log "Daemon seem ok."
      fi
    fi
    return 0
  }

  # This should force unstuck the local node.
  function ReconsiderBlock () {
    # If raptoreum-cli is responsive and it is stuck in the different place than before.
    if [[ $block_height -gt 0 && $block_height -gt $(ReadValue "/tmp/prev_stuck") ]]; then
      # Node is still responsive but is stuck on the wrong branch/fork.
      RECONSIDER=$(( block_height - 10 ))
      HASH=$(ReadCli getblockhash ${RECONSIDER})
      if [[ ${HASH} != "-1" ]]; then
        log "$(date -u)  Reconsider chain from 10 blocks before current one ${RECONSIDER}."
        if [[ -z $(ReadCli reconsiderblock "${HASH}") ]]; then
          echo ${RECONSIDER} >/tmp/height
          echo ${block_height} >/tmp/prev_stuck
          return 0
        fi
      fi
    fi
    # raptoreum-cli is/was unresponsive in at least 1 step
    return 1
  }
  # PoSe seems fine, did not change or was not able to get the score.
  ( CheckBlockHeight && CheckPoSe ) || ReconsiderBlock
