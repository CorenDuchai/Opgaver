#!/bin/bash
PCAP="live_exchange.pcap"

echo "### TCP stream for frame 4 ###"
tshark -r "$PCAP" -Y 'frame.number == 4' -T fields -e tcp.stream

echo ""
echo "### Fuld raw TCP-stream (stream 0, request + response) ###"
tshark -r "$PCAP" -q -z follow,tcp,ascii,0

echo ""
echo "### Alle .137 -> .91 requests, fulde headers ###"
tshark -r "$PCAP" -Y 'ip.src==77.233.186.137 && ip.dst==77.233.186.91 && http.request' -V \
  | grep -A 20 "Hypertext Transfer Protocol" | head -100
