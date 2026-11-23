#!/bin/bash
IP="77.74.147.54"

echo "### Portscan af .54 ###"
nmap -p- --min-rate 1000 -T4 "$IP"

echo ""
echo "### HTTP paa port 80 ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$IP/"

echo ""
echo "### Med Host-header secret-server.hkn (i tilfaelde vhost-routing) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$IP/" -H "Host: secret-server.hkn"

echo ""
echo "### /keycheck, /next_chars, /flag paa .54 med Host: secret-server.hkn ###"
for path in "/keycheck" "/next_chars" "/flag"; do
  echo "=== GET $path ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://$IP${path}" -H "Host: secret-server.hkn"
  echo ""
  echo "---"
done
