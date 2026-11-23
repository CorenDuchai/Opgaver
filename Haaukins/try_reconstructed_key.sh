#!/bin/bash
KEY='pwd:C%{6bSUAs52sI@$K8Ouk0'

echo "### Test paa magic-key.hkn/keycheck ###"
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$KEY"
echo ""
echo "---"

echo "### Uden sidste 0 (i tilfaelde af off-by-one) ###"
KEY2='pwd:C%{6bSUAs52sI@$K8Ouk'
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$KEY2"
echo ""
echo "---"

echo "### Uden 'pwd:' praefiks (i tilfaelde af det ikke er del af selve noeglen) ###"
KEY3='C%{6bSUAs52sI@$K8Ouk0'
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$KEY3"
echo ""
echo "---"
