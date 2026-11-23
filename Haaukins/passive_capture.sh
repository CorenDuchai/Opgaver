#!/bin/bash
echo "Lytter passivt i 30 sekunder paa eth0 efter trafik mellem magic-key.hkn (.91) og secret-server (.137)..."
echo "(ingen ARP-spoofing, kun lytning - paavirker ikke din forbindelse)"
timeout 30 tcpdump -i eth0 -n "(host 77.233.186.91 and host 77.233.186.137)" -c 50 2>&1

echo ""
echo "### Ogsaa: al trafik generelt i 15 sek, for at se om der er noget usaedvanligt ###"
timeout 15 tcpdump -i eth0 -n "not host 77.233.186.4 and not port 53" -c 30 2>&1
