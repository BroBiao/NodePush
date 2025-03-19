#!/bin/zsh

APP_NAME="w ai"
SERV_NAME=$(launchctl list | grep application.ai.wombo.wai | awk '{print $3}')
LOG_PATH="/Users/debiao/.wombo/cache/client.log"
MAX_SECONDS=300

now_time=$(date "+%m-%d %H:%M:%S")
log_modtime=$(stat -f %m "$LOG_PATH")
now_ts=$(date +%s)
time_diff=$((now_ts - log_modtime))
if [ $time_diff -gt $MAX_SECONDS ]; then
    echo "$now_time No new logs for $time_diff seconds, trying to restart..."
    if pgrep -xq "$APP_NAME"; then
	launchctl stop $SERV_NAME
	sleep 30
    fi
    open -a "$APP_NAME"
else
    echo "$now_time Everything is fine..."
fi
