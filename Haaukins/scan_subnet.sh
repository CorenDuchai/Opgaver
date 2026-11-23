#!/bin/bash
echo "### HTTP-probe mod .2 og .3 direkte ###"
for ip in 77.74.147.2 77.74.147.3; do
  echo "=== $ip port 80 ==="
  curl -s --connect-timeout 3 --max-time 5 -i "http://$ip/"
  echo ""
  echo "---"
done

echo ""
echo "### Hurtig nmap ping-sweep af hele subnettet ###"
nmap -sn 77.74.147.0/24 2>/dev/null || echo "(nmap ikke installeret - installerer)"
if ! command -v nmap >/dev/null 2>&1; then
  apt-get install -y nmap >/dev/null 2>&1
  nmap -sn 77.74.147.0/24
fi

echo ""
echo "### Port-scan af .2 og .3 for aabne porte ###"
nmap -p- --min-rate 1000 -T4 77.74.147.2 77.74.147.3 2>/dev/null
