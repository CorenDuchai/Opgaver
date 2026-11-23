#!/usr/bin/env python3
import requests

MAGIC = "magic-key.hkn"
DECOY = "dGhpcyB0b2tlbiBpcyBub3QgZ29vZA"

old_dates = [
    "Thu, 01 Jan 1970 00:00:00 GMT",
    "Fri, 02 Jan 1970 00:00:00 GMT",
    "Thu, 24 Dec 2015 00:00:00 GMT",
    "Fri, 01 Dec 2023 15:40:31 GMT",   # exact pcap capture start
    "Sun, 13 Mar 2011 07:06:40 GMT",    # 1300000000 as HTTP date
]

date_headers = ["If-Modified-Since", "If-Unmodified-Since", "Date"]

print("### Testing old-date HTTP headers against /flag (no Session-Token at all) ###")
for dh in date_headers:
    for d in old_dates:
        r = requests.get(f"http://{MAGIC}/flag", headers={dh: d}, timeout=5)
        if r.status_code != 401:
            print(f"!!! HIT {dh}={d} -> {r.status_code}: {r.text[:300]}")
        else:
            print(f"  {dh}={d} -> 401")

print("\n### Same, but combined with the known decoy Session-Token + URL-Maybe ###")
for dh in date_headers:
    for d in old_dates:
        headers = {dh: d, "Session-Token": DECOY, "URL-Maybe": "/flag"}
        r = requests.get(f"http://{MAGIC}/flag", headers=headers, timeout=5)
        if r.status_code != 401:
            print(f"!!! HIT {dh}={d} -> {r.status_code}: {r.text[:300]}")
        else:
            print(f"  {dh}={d} (+decoy) -> 401")
