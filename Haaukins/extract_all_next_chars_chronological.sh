#!/bin/bash
# Pull EVERY /next_chars request+response from the ORIGINAL magic.pcapng,
# in chronological order, with full timestamps -- to look for a SECOND,
# separate fragment sequence (distinct from the already-solved password chain)
# that might reconstruct cleanly into "Session-Token: <value>" directly.
PCAP="magic.pcapng"

echo "### ALL /next_chars requests+responses, chronological, with timestamps ###"
tshark -r "$PCAP" -Y 'http.request.full_uri contains "next_chars"' -T fields \
  -e frame.number -e frame.time_relative -e ip.src -e ip.dst \
  -e http.request.full_uri 2>/dev/null

echo ""
echo "### Matching responses (next http.file_data after each next_chars request), with time ###"
tshark -r "$PCAP" -Y 'http.response and http.file_data' -T fields \
  -e frame.number -e frame.time_relative -e http.file_data 2>/dev/null

echo ""
echo "### Look for ANY frame whose response body looks like it could be a header:value pair (contains a colon) ###"
tshark -r "$PCAP" -Y 'http.response and http.file_data contains ":"' -T fields \
  -e frame.number -e frame.time_relative -e http.file_data 2>/dev/null

echo ""
echo "### All distinct char= query params used across the WHOLE pcap, in order of first appearance ###"
tshark -r "$PCAP" -Y 'http.request.full_uri contains "next_chars"' -T fields \
  -e http.request.full_uri 2>/dev/null | sed -E 's/.*char=//' | awk '!seen[$0]++'

echo ""
echo "### Large time gaps between consecutive next_chars requests (might mark a phase boundary) ###"
tshark -r "$PCAP" -Y 'http.request.full_uri contains "next_chars"' -T fields \
  -e frame.time_relative 2>/dev/null | awk 'NR>1{diff=$1-prev; if (diff>5) print "Gap of " diff "s before line " NR " (t=" $1 ")"} {prev=$1}'
