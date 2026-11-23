#!/bin/bash
JWT_REAL="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6IkZhbHNlIiwidGltZXN0YW1wIjoiMTcwMTQ0NTIyNSJ9.ii2mBDI5IB0iTl31wud_UDqzUkch0ui8WVW0yHG00hg"
STOKEN="Session-Token: very-good-session-token"

echo "### 1) JWT_REAL som key-vaerdi (uden headers) ###"
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$JWT_REAL" | grep -A2 "Your message"
echo "---"

echo "### 2) 'Session-Token: very-good-session-token' som key-vaerdi (hele strengen) ###"
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$STOKEN" | grep -A2 "Your message"
echo "---"

echo "### 3) POST /keycheck MED JWT_REAL header + key=my-password ###"
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    -H "JWT: $JWT_REAL" \
    --data-raw "key=my-password" -D - | head -30
echo "---"

echo "### 4) POST /keycheck MED JWT_REAL header + key=very-good-session-token ###"
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    -H "JWT: $JWT_REAL" \
    --data-raw "key=very-good-session-token" -D - | head -30
echo "---"

echo "### 5) POST /keycheck MED JWT_REAL header, tom key ###"
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    -H "JWT: $JWT_REAL" \
    --data-raw "key=" -D - | head -30
echo "---"

echo "### 6) GET /keycheck MED JWT_REAL header (ikke POST) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/keycheck" \
    -H "JWT: $JWT_REAL"
echo "---"
