#!/bin/bash
# "Change Direction" - test 1: JWT som 'key' i POST /keycheck (i stedet for header)
# "Change Direction" - test 2: strenge reversed (omvendt raekkefoelge)

JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwidGltZXN0YW1wIjoxMzAwMDAwMDAwfQ.d-H00PqEmUozSDiQxSRWBYeyIqvuaTifVVBHlKaE2Wc"

rev() { echo -n "$1" | command rev; }

declare -a candidates=(
    "$JWT"
    "$(rev "$JWT")"
    "very-good-session-token"
    "$(rev "very-good-session-token")"
    "$(rev "my-password")"
    "$(rev "password:my-password")"
    "$(rev "DogeCoinToTheMoon1337")"
)

for key in "${candidates[@]}"; do
    echo "=== key=$key ==="
    curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
        -H "Content-Type: text/plain" \
        --data-raw "key=$key" | grep -A2 "Your message"
    echo "---"
done
