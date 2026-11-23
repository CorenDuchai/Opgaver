#!/bin/bash
# Updated for the new lab instance's IPs.
MAGIC_KEY_IP="77.76.10.55"
SECRET_SERVER_IP="77.76.10.37"
OUT="./full_cycle_capture.pcap"
DURATION=300

echo "Capturing $DURATION seconds of traffic between $SECRET_SERVER_IP and $MAGIC_KEY_IP ..."
sudo timeout $DURATION tcpdump -i eth0 -n -w "$OUT" "host $MAGIC_KEY_IP and host $SECRET_SERVER_IP"

echo ""
echo "### Chronological list of every request (method + full URI) ###"
tshark -r "$OUT" -Y "http.request" -T fields \
  -e frame.number -e frame.time_relative -e ip.src -e http.request.method -e http.request.full_uri 2>/dev/null | head -300

echo ""
echo "### All distinct request header blocks seen (to catch Session-Token/URL values) ###"
tshark -r "$OUT" -Y "http.request" -T fields -e frame.time_relative -e http.request.line 2>/dev/null | sort -u

echo ""
echo "### All response bodies in order (to see if content ever changes from the joke decoys) ###"
tshark -r "$OUT" -Y "http.response and http.file_data" -T fields \
  -e frame.time_relative -e http.response.code -e http.file_data
