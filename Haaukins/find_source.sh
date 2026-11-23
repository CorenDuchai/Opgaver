#!/bin/bash
# Prøv at finde kildekoden bag magic-key.hkn (Python SimpleHTTPRequestHandler serverer ofte cwd direkte)
for f in app.py server.py main.py magic-key.py magic_key.py index.py run.py \
         handler.py web.py secret.py config.py app.cfg settings.py \
         requirements.txt .git/config index.html index.css \
         __pycache__/app.cpython-39.pyc __pycache__/server.cpython-39.pyc \
         flag.txt key.txt secret.txt .env; do
    code=$(curl -s -o /tmp/resp_body -w "%{http_code}" "http://magic-key.hkn/$f")
    if [ "$code" == "200" ]; then
        echo "=== [200] /$f ==="
        cat /tmp/resp_body
        echo ""
        echo "---"
    else
        echo "[$code] /$f"
    fi
done
