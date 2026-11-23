#!/bin/bash
# Session-Token alene (uden JWT), mod alle kendte stier paa magic-key.hkn
for path in "/" "/next_chars" "/flag" "/keycheck"; do
  echo "=== GET $path med Session-Token: very-good-session-token ==="
  curl -s -i "http://magic-key.hkn${path}" \
    -H "Session-Token: very-good-session-token"
  echo ""
  echo "---"
done
