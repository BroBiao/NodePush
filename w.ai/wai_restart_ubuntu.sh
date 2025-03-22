#!/bin/bash

APP_NAME="w.ai"
SERV_NAME="wai.service"
LOG_PATH="/home/debiao/.wombo/cache/client.log"
MAX_SECONDS=300

now_time=$(date "+%m-%d %H:%M:%S")
log_modtime=$(tail -n 1 $LOG_PATH | cut -d ',' -f1 | xargs -I {} date -d "{}" +%s)
now_ts=$(date +%s)
time_diff=$((now_ts - log_modtime))
if [ $time_diff -gt $MAX_SECONDS ]; then
    echo "$now_time No new logs for $time_diff seconds, trying to restart..."
    /usr/bin/systemctl restart $SERV_NAME
else
    echo "$now_time Everything is fine..."
fi

