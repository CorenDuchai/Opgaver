#!/bin/bash
KEY='C%{6bSUAs52sI@$K8Ouk0'

echo "### Fuld response (headers + body) for den genkendte noegle paa magic-key.hkn ###"
curl -s --connect-timeout 3 --max-time 5 -i -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$KEY"
echo ""
