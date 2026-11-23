#!/bin/bash
# Tjek om der er HTTP-trafik i pcap'en TIL/FRA magic-key.hkn selv (ikke kun secret-server.hkn)
PCAP="magic.pcapng"

echo "=== Alle unikke HTTP Host-headers i pcap'en ==="
tshark -r "$PCAP" -Y http.request -T fields -e http.host | sort -u

echo ""
echo "=== Alle unikke destinations-IP'er for HTTP-trafik ==="
tshark -r "$PCAP" -Y http -T fields -e ip.dst | sort -u

echo ""
echo "=== Fuld HTTP-request/response oversigt med IP (ikke kun host-header) ==="
tshark -r "$PCAP" -Y http -T fields -e frame.number -e ip.src -e ip.dst -e http.host -e http.request.full_uri -e http.request.method -e http.response.code
