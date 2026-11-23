#!/bin/bash
SS="77.74.147.54"
HOST="Host: secret-server.hkn"

echo "### GET /keycheck?key=test (maaske GET i stedet for POST paa denne instans) ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/keycheck?key=test" -H "$HOST"
echo ""
echo "---"

echo "### GET /next_chars?char=s UDEN JWT (se om det virker uautentificeret) ###"
curl -s --connect-timeout 3 --max-time 5 "http://$SS/next_chars?char=s" -H "$HOST"
echo ""
echo "---"

echo "### Kald /next_chars?char=s 10 gange i traek UDEN JWT - se om svar aendrer sig/cykler ###"
for i in $(seq 1 10); do
  echo "--- kald $i ---"
  curl -s --connect-timeout 3 --max-time 5 "http://$SS/next_chars?char=s" -H "$HOST"
  echo ""
done

echo ""
echo "### Proev forskellige enkelt-bogstaver som char, UDEN JWT ###"
for c in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
  resp=$(curl -s --connect-timeout 3 --max-time 5 "http://$SS/next_chars?char=$c" -H "$HOST")
  echo "char=$c -> $resp"
done
