#!/bin/bash
OUT="./trigger_capture.pcap"
KEY='C%{6bSUAs52sI@$K8Ouk0'

echo "Starter capture i baggrunden..."
sudo timeout 60 tcpdump -i eth0 -n -w "$OUT" "host 77.233.186.91 and host 77.233.186.137" &
TCPDUMP_PID=$!

sleep 5
echo "Sender vores keycheck NU..."
curl -s -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$KEY" | grep -A2 "Your message"

echo "Venter resten af capture-vinduet..."
wait $TCPDUMP_PID

echo ""
echo "### Response bodies EFTER vores keycheck (kronologisk) ###"
tshark -r "$OUT" -Y "http.response and http.file_data" -T fields -e frame.number -e frame.time_relative -e http.file_data
