#!/bin/bash
echo "### Egen IP/subnet ###"
ip -4 addr show | grep -E "inet |^[0-9]+:"

echo ""
echo "### magic-key.hkn IP ###"
getent hosts magic-key.hkn

echo ""
echo "### Ping-sweep af eget /24 ###"
MYIP=$(ip -4 addr show eth0 | grep -oP 'inet \K[0-9.]+')
SUBNET=$(echo "$MYIP" | cut -d. -f1-3)
nmap -sn "${SUBNET}.0/24" 2>/dev/null || { apt-get install -y nmap >/dev/null 2>&1; nmap -sn "${SUBNET}.0/24"; }
