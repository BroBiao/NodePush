#!/bin/bash

SERV_NAME="tracksd.service"
ERR1="rpc error: code = Unavailable desc = incorrect pod number"
ERR2="rpc error: code = Unknown desc = failed to execute message"
ERR3="Failed to Init VRF"
ERR4="Failed to unmarshal transaction"
ERR5="Failed to Transact Verify pod"
ERR6="VRF record is nil"
ERR7="Failed to Validate VRF"
ALL_ERRS="$ERR1|$ERR2|$ERR3|$ERR4|$ERR5|$ERR6|$ERR7"

ACCOUNT_TOKEN='your_dicord_token'
CHANNEL_ID='1238910689188511835'
MSG_TEXT='$faucet airxxxxxxxxxxxxxxxxxxxxxxxxx'
FUND_ERR="Error=\"error code: '5' msg: 'spendable balance"

function rollback_restart() {
    echo "Stopping..."
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

function send_discord_message() {
    local account_token="$1"
    local channel_id="$2"
    local message_text="$3"

    local nonce=$(($(date +%s%N)/1000000 + RANDOM))

    local payload=$(cat <<EOF
{
    "mobile_network_type": "unknown",
    "content": "$message_text",
    "nonce": "$nonce",
    "tts": false,
    "flags": 0
}
EOF
)

    local response=$(curl -s -X POST \
        -H "Authorization: $account_token" \
        -H "Content-Type: application/json" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36" \
        -d "$payload" \
        "https://discord.com/api/v9/channels/$channel_id/messages")
}

while true; do
    log_lines=$(journalctl -u ${SERV_NAME} -n 10)
    last_log_ts=$(( $(journalctl --no-pager --output=json -n 1 -u $SERV_NAME | jq -r '.["__REALTIME_TIMESTAMP"]') / 1000000 ))
    now_ts=$(date +"%s")
    wait_time=$((now_ts - last_log_ts))
    if echo "$log_lines" | grep -q "$FUND_ERR"; then
        echo "Insufficient funds! Calling Discord faucet..."
        send_discord_message "$ACCOUNT_TOKEN" "$CHANNEL_ID" "$MSG_TEXT"
        systemctl restart $SERV_NAME
    elif echo "$log_lines" | grep -Eq "$ALL_ERRS"; then
        echo "Error detected!"
        rollback_restart
    elif [ $wait_time -gt 600 ]; then
        echo "Long wait!"
        rollback_restart
    else
        echo "listening......"
    fi
    sleep 60
done
