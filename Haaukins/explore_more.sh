#!/bin/bash

echo "### Fulde response-headers paa POST /keycheck (kigger efter Set-Cookie e.l.) ###"
curl -s --connect-timeout 3 --max-time 5 -D - -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=test" -o /dev/null
echo "---"

echo "### Fulde response-headers paa GET / ###"
curl -s --connect-timeout 3 --max-time 5 -D - "http://magic-key.hkn/" -o /dev/null
echo "---"

echo "### index.css - indhold (kig efter kommentarer/hints) ###"
curl -s --connect-timeout 3 --max-time 5 "http://magic-key.hkn/index.css"
echo "---"

echo "### robots.txt ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/robots.txt"
echo "---"

echo "### favicon.ico headers ###"
curl -s --connect-timeout 3 --max-time 5 -I "http://magic-key.hkn/favicon.ico"
echo "---"

echo "### OPTIONS paa / (ser hvilke metoder serveren tillader) ###"
curl -s --connect-timeout 3 --max-time 5 -i -X OPTIONS "http://magic-key.hkn/"
echo "---"

echo "### OPTIONS paa /keycheck ###"
curl -s --connect-timeout 3 --max-time 5 -i -X OPTIONS "http://magic-key.hkn/keycheck"
echo "---"

echo "### HEAD paa /next_chars (evt extra headers uden body) ###"
curl -s --connect-timeout 3 --max-time 5 -I "http://magic-key.hkn/next_chars"
echo "---"
