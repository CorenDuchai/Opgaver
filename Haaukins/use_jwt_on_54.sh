#!/bin/bash
SS="77.74.147.54"
HOST="Host: secret-server.hkn"
JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6ZmFsc2UsInRpbWVzdGFtcCI6MTc5MjA5NTY3NH0.zmgK9_RE0on0YplSDxr3wKgZooA5wchwO4rx6zjsk9s"

echo "### GET /flag paa .54 med den nye JWT ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/flag" -H "$HOST" -H "JWT: $JWT"
echo ""
echo "---"

echo "### GET / paa .54 med den nye JWT ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/" -H "$HOST" -H "JWT: $JWT"
echo ""
echo "---"

echo "### GET /next_chars?char=s paa .54 med den nye JWT ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/next_chars?char=s" -H "$HOST" -H "JWT: $JWT"
echo ""
echo "---"

echo "### GET /keycheck paa .54 med den nye JWT (i tilfaelde af GET nu er tilladt) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/keycheck" -H "$HOST" -H "JWT: $JWT"
echo ""
echo "---"
