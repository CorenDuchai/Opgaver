#!/bin/bash
# Footer-dato "02-01-1970" som mulig "magic key" - forskellige formater
declare -a candidates=(
    "02-01-1970"
    "01-02-1970"
    "1970-01-02"
    "1970-02-01"
    "02011970"
    "01021970"
    "19700102"
    "19700201"
    "86400"
    "0"
    "1"
    "2"
)

for key in "${candidates[@]}"; do
    echo "=== key=$key ==="
    curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
        -H "Content-Type: text/plain" \
        --data-raw "key=$key" | grep -A2 "Your message"
    echo "---"
done
