#!/bin/bash
# Longer passive capture to see whether Session-Token value ROTATES over time,
# and whether the .137<->.91 traffic ever transitions from decoy phase to a
# "real" phase (mirroring the pcap's decoy->real transition).
# Adjust IPs if your lab has been reset since last time.
MAGIC_KEY_IP="77.233.186.91"
SECRET_SERVER_IP="77.233.186.137"
OUT="./full_cycle_capture.pcap"
DURATION=300

echo "Capturing $DURATION seconds of traffic between $SECRET_SERVER_IP and $MAGIC_KEY_IP ..."
sudo timeout $DURATION tcpdump -i eth0 -n -w "$OUT" "host $MAGIC_KEY_IP and host $SECRET_SERVER_IP"

echo ""
echo "### Chronological list of every request with its Session-Token / URL-Maybe headers ###"
tshark -r "$OUT" -Y "http.request" -T fields \
  -e frame.number -e frame.time_relative -e http.request.method -e http.request.full_uri \
  -e "http.request.line" 2>/dev/null | head -200

echo ""
echo "### Just the Session-Token values, in order, to check if they rotate ###"
tshark -r "$OUT" -Y 'http.request and http contains "Session-Token"' -T fields \
  -e frame.time_relative -e http.request.full_uri -e http.file_data 2>/dev/null

echo ""
echo "### All response bodies in order (to see if content ever changes from the joke decoys) ###"
tshark -r "$OUT" -Y "http.response and http.file_data" -T fields \
  -e frame.time_relative -e http.response.code -e http.file_data
