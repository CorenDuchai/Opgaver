#!/bin/bash
# Verify the unnamed host (.37) is the secret-server, same role as .137/.54 in past resets.
TARGET="77.76.10.37"

echo "### Port scan of $TARGET ###"
sudo nmap -p- -T4 "$TARGET" 2>/dev/null | grep -E "open|PORT"

echo ""
echo "### HTTP probe (root) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/"

echo ""
echo "### HTTP probe (/next_chars, mimicking old secret-server behavior) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$TARGET/next_chars?char=a"

echo ""
echo "### Reverse DNS check (should have none, like before) ###"
getent hosts "$TARGET" || echo "(no DNS name, as expected)"
