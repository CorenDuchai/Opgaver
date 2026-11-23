#!/bin/bash
# "Change Direction" - bogstaveligt: vend den fundne streng om

FORWARD='C%{6bSUAs52sI@$K8Ouk0'
REVERSED=$(echo -n "$FORWARD" | rev)

echo "Forward:  $FORWARD"
echo "Reversed: $REVERSED"
echo ""

echo "### Test reversed (uden pwd:) ###"
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$REVERSED" | grep -A2 "Your message"
echo "---"

echo "### Test reversed MED pwd: praefiks ###"
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=pwd:$REVERSED" | grep -A2 "Your message"
echo "---"

echo "### Test reversed af HELE pwd:-strengen (inkl. praefiks foer vending) ###"
FULL='pwd:C%{6bSUAs52sI@$K8Ouk0'
FULL_REV=$(echo -n "$FULL" | rev)
echo "Reversed hele: $FULL_REV"
curl -s --connect-timeout 3 --max-time 5 -X POST "http://magic-key.hkn/keycheck" \
    -H "Content-Type: text/plain" \
    --data-raw "key=$FULL_REV" | grep -A2 "Your message"
echo "---"
