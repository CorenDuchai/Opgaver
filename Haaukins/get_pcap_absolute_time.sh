#!/bin/bash
PCAP="magic.pcapng"

echo "### Capture file metadata (absolute start/end time) ###"
capinfos "$PCAP" 2>/dev/null || tshark -r "$PCAP" -q -z io,stat,0 2>/dev/null | head -5

echo ""
echo "### Absolute timestamp of first and last frame ###"
tshark -r "$PCAP" -T fields -e frame.time -e frame.time_epoch 2>/dev/null | head -1
echo "..."
tshark -r "$PCAP" -T fields -e frame.time -e frame.time_epoch 2>/dev/null | tail -1

echo ""
echo "### HTTP Date: response headers seen in the pcap (server's own clock at capture time) ###"
tshark -r "$PCAP" -Y "http.response" -T fields -e frame.time -e http.date 2>/dev/null | head -20

echo ""
echo "### Unix epoch of the frames around the successful 'Session-Token' sequence (frames ~17433-17500) ###"
tshark -r "$PCAP" -Y "frame.number >= 17430 && frame.number <= 17510" -T fields -e frame.number -e frame.time -e frame.time_epoch 2>/dev/null
