#!/bin/bash
SS="77.74.147.54"
HOST="Host: secret-server.hkn"
OUT="/tmp/charset_results.txt"
> "$OUT"

# Lowercase, uppercase, digits, og almindelige symboler
CHARS=$(python3 -c "import string; print(' '.join(list(string.ascii_letters + string.digits + '!@#\$%^&*()_+-=:;,.<>?/~\`|\\\\[]{}')))")

for c in $CHARS; do
  # URL-encode saerlige tegn
  enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$c")
  resp=$(curl -s --connect-timeout 2 --max-time 3 "http://$SS/next_chars?char=$enc" -H "$HOST" | tr -d '\n' | tr -s ' ')
  if [[ "$resp" != "[]" && -n "$resp" ]]; then
    echo "char=$c -> $resp" | tee -a "$OUT"
  fi
done

echo ""
echo "=== Alle ikke-tomme resultater gemt i $OUT ==="
cat "$OUT"
