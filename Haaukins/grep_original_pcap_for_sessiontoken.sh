#!/bin/bash
# Search the ORIGINAL magic.pcapng (not the live capture) for any Session-Token / URL-Maybe
# / flag traffic we might have missed while focused on the fragment-chain.
# Run this from wherever magic.pcapng lives on your machine.
PCAP="magic.pcapng"

echo "### Any frame mentioning Session-Token ###"
tshark -r "$PCAP" -Y 'http contains "Session-Token"' -T fields -e frame.number -e frame.time_relative -e ip.src -e ip.dst -e http.request.full_uri -e http.file_data

echo ""
echo "### Any frame mentioning URL-Maybe ###"
tshark -r "$PCAP" -Y 'http contains "URL-Maybe"' -T fields -e frame.number -e frame.time_relative -e ip.src -e ip.dst -e http.request.full_uri -e http.file_data

echo ""
echo "### Any frame mentioning /flag ###"
tshark -r "$PCAP" -Y 'http contains "/flag"' -T fields -e frame.number -e frame.time_relative -e ip.src -e ip.dst -e http.request.full_uri -e http.response.code -e http.file_data

echo ""
echo "### Full list of ALL distinct HTTP request headers seen anywhere in the pcap ###"
tshark -r "$PCAP" -Y "http.request" -T fields -e http.request.line | sort -u

echo ""
echo "### Full list of ALL distinct custom header NAMES (to spot anything odd) ###"
tshark -r "$PCAP" -Y "http" -T fields -e http.request.line -e http.response.line 2>/dev/null | tr ';' '\n' | grep -oE '^[A-Za-z-]+:' | sort -u
