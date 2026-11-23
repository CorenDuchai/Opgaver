#!/bin/bash
# Prøv forskellige kandidat-nøgler mod magic-key.hkn/keycheck
# enctype=text/plain betyder raw body "key=<value>" uden URL-encoding af selve værdien

declare -a candidates=(
    "my-password"
    "password:my-password"
    "assword:my-password"
    "very-good-session-token"
    "Session-Token: very-good-session-token"
    "session-token:very-good-session-token"
    "DogeCoinToTheMoon1337"
    "magic-key"
    "RansomGang"
)

for key in "${candidates[@]}"; do
    echo "=== key=$key ==="
    curl -s -X POST "http://magic-key.hkn/keycheck" \
        -H "Content-Type: text/plain" \
        --data-raw "key=$key"
    echo ""
    echo "---"
done
