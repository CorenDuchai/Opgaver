#!/bin/bash
PCAP="magic.pcapng"

echo "=== Frame 15077: POST /keycheck - REQUEST BODY (den rigtige magic key!) ==="
tshark -r "$PCAP" -Y "frame.number==15077" -T fields -e http.file_data -e http.request.full_uri -e text

echo ""
echo "=== Frame 15077 fuld detalje (alle lag) ==="
tshark -r "$PCAP" -Y "frame.number==15077" -V | grep -A 50 "Hypertext Transfer Protocol"

echo ""
echo "=== Frame 15083: Response paa keycheck ==="
tshark -r "$PCAP" -Y "frame.number==15083" -T fields -e http.file_data

echo ""
echo "=== Frame 15083 fuld detalje ==="
tshark -r "$PCAP" -Y "frame.number==15083" -V | grep -A 50 "Hypertext Transfer Protocol"

echo ""
echo "=== Frame 17500: Response paa GET /flag (DET RIGTIGE FLAG!) ==="
tshark -r "$PCAP" -Y "frame.number==17500" -T fields -e http.file_data

echo ""
echo "=== Frame 17500 fuld detalje ==="
tshark -r "$PCAP" -Y "frame.number==17500" -V | grep -A 50 "Hypertext Transfer Protocol"

echo ""
echo "=== Alle chars i rigtig raekkefoelge med retning (frame, src, dst, char) ==="
tshark -r "$PCAP" -Y "http.request.uri contains \"next_chars\"" -T fields -e frame.number -e ip.src -e ip.dst -e http.request.uri.query.parameter
