#!/bin/bash
PCAP="magic.pcapng"

echo "=== Alle next_chars REQUESTS (frame, retning, char sendt) ==="
tshark -r "$PCAP" -Y "http.request.uri contains \"next_chars\"" -T fields -e frame.number -e ip.src -e ip.dst -e http.request.uri.query.parameter

echo ""
echo "=== Alle next_chars RESPONSES (frame, body) - DEN RIGTIGE KARAKTER ==="
tshark -r "$PCAP" -Y "http.response and http.request_in" -T fields -e frame.number -e http.request_in -e http.file_data -e http.response.code | \
  while IFS=$'\t' read -r fn reqfn data code; do
    req_uri=$(tshark -r "$PCAP" -Y "frame.number==$reqfn" -T fields -e http.request.full_uri 2>/dev/null)
    if [[ "$req_uri" == *next_chars* ]]; then
      echo "frame=$fn (request=$reqfn) code=$code data=[$data]"
    fi
  done

echo ""
echo "=== JWT-headers i ALLE responses (for at se om JWT roterer) ==="
tshark -r "$PCAP" -Y "http.response" -T fields -e frame.number -e "http.response.line" 2>/dev/null | grep -i jwt

echo ""
echo "=== Alternativ: direkte JWT header-vaerdi pr response frame ==="
tshark -r "$PCAP" -Y "http.response" -T fields -e frame.number -e http.response.code | while read -r fn code; do
  jwt=$(tshark -r "$PCAP" -Y "frame.number==$fn" -V 2>/dev/null | grep "^    JWT:")
  if [ -n "$jwt" ]; then
    echo "frame=$fn code=$code $jwt"
  fi
done
