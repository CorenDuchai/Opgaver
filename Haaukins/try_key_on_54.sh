#!/bin/bash
SS="77.74.147.54"
HOST="Host: secret-server.hkn"
KEY='C%{6bSUAs52sI@$K8Ouk0'
ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$KEY")

echo "### GET /keycheck?key=<noegle> paa .54 ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/keycheck?key=$ENC" -H "$HOST"
echo ""
echo "---"

echo "### Samme men med 'pwd:' praefiks ###"
KEY2='pwd:C%{6bSUAs52sI@$K8Ouk0'
ENC2=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$KEY2")
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/keycheck?key=$ENC2" -H "$HOST"
echo ""
echo "---"

echo "### PUT /keycheck (i tilfaelde af det er den forventede metode) ###"
curl -s --connect-timeout 3 --max-time 5 -i -X PUT "http://$SS/keycheck" \
    -H "$HOST" -H "Content-Type: text/plain" --data-raw "key=$KEY"
echo ""
echo "---"
