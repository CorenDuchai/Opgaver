#!/bin/bash
WORDLIST="/usr/share/wordlists/dirb/common.txt"

echo "### ffuf uden -s, med fuld output ###"
ffuf -u "http://magic-key.hkn/FUZZ" -w "$WORDLIST" -mc all -fc 403,404,401 -t 10

echo ""
echo "### Exit code: $? ###"

echo ""
echo "### Sanity check: plain curl mod kendt sti ###"
curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://magic-key.hkn/"
curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://magic-key.hkn/index.css"
curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://magic-key.hkn/robots.txt"
