#!/bin/bash
KEY='C%{6bSUAs52sI@$K8Ouk0'
ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$KEY")

echo "### GET /<noegle> direkte som sti paa magic-key.hkn ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/$ENC"
echo ""; echo "---"

echo "### GET /keycheck/<noegle> paa magic-key.hkn ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/keycheck/$ENC"
echo ""; echo "---"

echo "### GET /next_chars/s (path-stil i stedet for ?char=s) paa magic-key.hkn ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/next_chars/s"
echo ""; echo "---"

echo "### GET /flag/<noegle> paa magic-key.hkn ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/flag/$ENC"
echo ""; echo "---"
