#!/bin/bash

echo "### GET /srahc_txen (next_chars baglaens) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/srahc_txen"
echo ""; echo "---"

echo "### GET /srahc_txen?char=s ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/srahc_txen?char=s"
echo ""; echo "---"

echo "### GET /galf (flag baglaens) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/galf"
echo ""; echo "---"

echo "### GET /kcehcyek (keycheck baglaens) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/kcehcyek"
echo ""; echo "---"

echo "### POST /kcehcyek med key=... ###"
curl -s --connect-timeout 3 --max-time 5 -i -X POST "http://magic-key.hkn/kcehcyek" \
    -H "Content-Type: text/plain" --data-raw 'key=C%{6bSUAs52sI@$K8Ouk0'
echo ""; echo "---"
