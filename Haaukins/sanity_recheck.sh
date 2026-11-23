#!/bin/bash
echo "### DNS for magic-key.hkn ###"
getent hosts magic-key.hkn

echo ""
echo "### Svarer .54 stadig paa samme maade? ###"
curl -s --connect-timeout 3 --max-time 5 "http://77.74.147.54/next_chars?char=p" -H "Host: secret-server.hkn"
echo ""
echo "(hvis dette IKKE er [\"wd:\"] er secret-server sandsynligvis en NY instans med nyt data)"

echo ""
echo "### Footer-dato stadig samme? ###"
curl -s --connect-timeout 3 --max-time 5 "http://magic-key.hkn/" | grep -i "Copyright"
