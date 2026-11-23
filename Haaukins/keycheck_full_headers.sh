#!/bin/bash
# Re-run the keycheck POST (this time against magic-key.hkn, since that's the
# server actually enforcing Session-Token), and dump EVERY response header,
# not just the body -- in case it issues a real Session-Token via a header
# like Set-Cookie or Session-Token or similar.
KEY='C%{6bSUAs52sI@$K8Ouk0'

echo "### POST /keycheck to magic-key.hkn with reconstructed key, FULL response (headers + body) ###"
curl -s --connect-timeout 3 --max-time 5 -i -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$KEY"
echo ""; echo "---"

echo "### Same, but against secret-server (.37) for comparison ###"
curl -s --connect-timeout 3 --max-time 5 -i -X POST "http://77.76.10.37/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$KEY"
echo ""; echo "---"

echo "### GET /keycheck (no POST) on magic-key.hkn, to see if it behaves differently ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/keycheck"
echo ""; echo "---"

echo "### Does magic-key.hkn issue anything on / (root) worth checking headers for? ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/"
echo ""; echo "---"
