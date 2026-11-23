#!/bin/bash
echo "### DNS-opslag ###"
getent hosts secret-server.hkn
getent hosts magic-key.hkn

echo ""
echo "### Er secret-server.hkn overhovedet oppe lige nu? ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://secret-server.hkn/" | head -20

echo ""
echo "### ARP-tabel (hvad kan vi se paa det lokale segment) ###"
arp -a 2>/dev/null || ip neigh

echo ""
echo "### Din egen IP/interface ###"
ip -4 addr show | grep -E "inet |^[0-9]+:"

echo ""
echo "### Traceroute/ping til begge for at se om de er paa samme segment ###"
ping -c 2 -W 2 secret-server.hkn
ping -c 2 -W 2 magic-key.hkn
