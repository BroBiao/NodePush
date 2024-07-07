#!/bin/bash

SERV_NAME="tracksd.service"
ERR1="rpc error: code = Unavailable desc = incorrect pod number"
ERR2="rpc error: code = Unknown desc = failed to execute message"
ERR3="Failed to Init VRF"
ERR4="Failed to unmarshal transaction"
ERR5="Failed to Transact Verify pod"
ERR6="VRF record is nil"
ALL_ERRS="$ERR1|$ERR2|$ERR3|$ERR4|$ERR5|$ERR6"

function rollback_restart() {
    echo "Error detected, stopping..."
    systemctl stop $SERV_NAME
    cd /root/tracks/
    roll_times=$(( RANDOM % 3 + 1 ))
    echo "Rolling back $roll_times pods..."
    for (( i=0; i<$roll_times; i++ )); do
        /usr/local/go/bin/go run ./cmd/main.go rollback
    done
    echo "Restarting..."
    systemctl restart $SERV_NAME
}

while true; do
    log_lines=$(journalctl -u ${SERV_NAME} -n 10)
    last_log_ts=$(( $(journalctl --no-pager --output=json -n 1 -u $SERV_NAME | jq -r '.["__REALTIME_TIMESTAMP"]') / 1000000 ))
    now_ts=$(date +"%s")
    wait_time=$((now_ts - last_log_ts))
    if echo "$log_lines" | grep -Eq "$ALL_ERRS"; then
        rollback_restart
    elif [ $wait_time -gt 600 ]; then
        rollback_restart
    else
        echo "listening......"
    fi
    sleep 60
done
