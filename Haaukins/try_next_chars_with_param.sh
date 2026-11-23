#!/bin/bash
# /next_chars med ?char=X parameter (som i den rigtige server-til-server protokol fra pcap'en),
# i stedet for uden parameter. Praver med JWT2 (admin:true, timestamp:1300000000).

JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwidGltZXN0YW1wIjoxMzAwMDAwMDAwfQ.d-H00PqEmUozSDiQxSRWBYeyIqvuaTifVVBHlKaE2Wc"

for c in "" "A" "a" "0" "1" " "; do
    echo "=== /next_chars?char=$c ==="
    curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/next_chars?char=$c" \
        -H "JWT: $JWT"
    echo ""
    echo "---"
done

echo "=== /next_chars uden ? (baseline) ==="
curl -s --connect-timeout 3 --max-time 5 -i "http://magic-key.hkn/next_chars" \
    -H "JWT: $JWT"
echo ""
