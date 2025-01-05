#!/bin/bash

CONTAINER_NAME=crynux_node
LAST_LOG_FILE=/root/NodeWatch/crynux/last.log
NODE_PATH=/root/crynux-node-docker-compose

docker logs "$CONTAINER_NAME" --tail 1 > $LAST_LOG_FILE 2>&1
last_log_ts=$(awk -F'[][]' '{print $2}' $LAST_LOG_FILE | xargs -I {} date -d "{}" +%s)
now_ts=$(date +"%s")
stuck_time=$((now_ts - last_log_ts))
if [ $stuck_time -gt 900 ]; then
    echo "crynux_node is stuck for $stuck_time seconds, restarting..."
    cd $NODE_PATH
    /usr/bin/docker compose down -v
    /usr/bin/docker compose up -d
else
    :
fi
rm $LAST_LOG_FILE
