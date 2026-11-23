#!/bin/bash
# Brute-force stier paa magic-key.hkn - leder efter ALT andet end 403/404/401
# Bruger ffuf hvis tilgaengeligt, ellers gobuster, ellers en simpel curl-loop

URL="http://magic-key.hkn/FUZZ"
WORDLIST=""
for wl in /usr/share/wordlists/dirb/common.txt /usr/share/seclists/Discovery/Web-Content/common.txt /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt; do
    if [ -f "$wl" ]; then
        WORDLIST="$wl"
        break
    fi
done

if [ -z "$WORDLIST" ]; then
    echo "Ingen standard-wordlist fundet - installerer dirb's common.txt via apt..."
    apt-get install -y dirb >/dev/null 2>&1
    WORDLIST="/usr/share/wordlists/dirb/common.txt"
fi

echo "Bruger wordlist: $WORDLIST ($(wc -l < "$WORDLIST") ord)"
echo ""

if command -v ffuf >/dev/null 2>&1; then
    echo "### Koerer ffuf ###"
    ffuf -u "$URL" -w "$WORDLIST" -mc all -fc 403,404,401 -t 20 -s
elif command -v gobuster >/dev/null 2>&1; then
    echo "### Koerer gobuster ###"
    gobuster dir -u "http://magic-key.hkn/" -w "$WORDLIST" -b 403,404,401 -t 20
else
    echo "### Hverken ffuf eller gobuster fundet - installerer ffuf ###"
    apt-get install -y ffuf >/dev/null 2>&1
    if command -v ffuf >/dev/null 2>&1; then
        ffuf -u "$URL" -w "$WORDLIST" -mc all -fc 403,404,401 -t 20 -s
    else
        echo "Kunne ikke installere ffuf/gobuster - falder tilbage til simpel curl-loop (langsommere)"
        while read -r word; do
            [ -z "$word" ] && continue
            code=$(curl -s --connect-timeout 2 --max-time 3 -o /dev/null -w "%{http_code}" "http://magic-key.hkn/$word")
            if [[ "$code" != "403" && "$code" != "404" && "$code" != "401" ]]; then
                echo "[$code] /$word"
            fi
        done < "$WORDLIST"
    fi
fi
