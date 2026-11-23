#!/bin/bash
KEY='C%{6bSUAs52sI@$K8Ouk0'

echo "### POST /keycheck paa NY magic-key.hkn instans ###"
curl -s --connect-timeout 3 --max-time 5 -i -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$KEY"
echo ""
