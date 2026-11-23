#!/bin/bash
OUT="./live_exchange.pcap"
echo "Indfanger live trafik mellem .91 og .137 i 90 sekunder til $OUT ..."
sudo timeout 90 tcpdump -i eth0 -n -w "$OUT" "host 77.233.186.91 and host 77.233.186.137"

echo ""
echo "### Faerdig. Udtraekker alle /next_chars request+response par ###"
tshark -r "$OUT" -Y "http.request.uri contains \"next_chars\"" -T fields -e frame.number -e ip.src -e ip.dst -e http.request.uri.query.parameter

echo ""
echo "### Response bodies (de rigtige fragmenter fra magic-key.hkn!) ###"
tshark -r "$OUT" -Y "http.response and http.file_data" -T fields -e frame.number -e http.file_data
