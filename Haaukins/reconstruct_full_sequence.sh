#!/bin/bash
PCAP="magic.pcapng"

FRAMES="7265 7361 7381 8018 8035 8108 8135 8158 9902 9921 10650 12413 12427 12445 12459 12471 12509 12523 15077 15104 15158 17433 17446 17459 17473 17496"

for fn in $FRAMES; do
    echo "################ FRAME $fn ################"
    tshark -r "$PCAP" -Y "frame.number==$fn" -V 2>/dev/null | sed -n '/Hypertext Transfer Protocol/,/^$/p' | head -40
    echo ""
done
