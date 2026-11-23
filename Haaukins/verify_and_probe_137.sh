#!/bin/bash
SS="77.233.186.137"
HOST="Host: secret-server.hkn"

echo "### Portscan ###"
nmap -p- --min-rate 1000 -T4 "$SS" 2>/dev/null

echo ""
echo "### GET / ###"
curl -s --connect-timeout 3 --max-time 5 -i "http://$SS/" -H "$HOST"
echo ""

echo "### GET /next_chars?char=s (sanity, bruger kendt start-boogstav fra sidst) ###"
curl -s --connect-timeout 3 --max-time 5 "http://$SS/next_chars?char=s" -H "$HOST"
echo ""

echo "### Fuldt tegnsaet-probe (uautentificeret) ###"
python3 -c "
import requests, string
SS='$SS'
charset = list(string.ascii_letters + string.digits + '!@#\$%^&*()_+-=:;,.<>?/~\`|\\\\[]{}')
results = {}
for c in charset:
    try:
        r = requests.get(f'http://{SS}/next_chars', params={'char': c}, headers={'Host':'secret-server.hkn'}, timeout=3)
        if r.text.strip() not in ('[]',''):
            results[c] = r.text.strip()
    except Exception:
        pass
for c,v in results.items():
    print(f'char={c!r} -> {v}')
print(f'Antal ikke-tomme: {len(results)}')
"
