#!/usr/bin/env python3
import requests

SS = "77.233.186.137"
HOST = "secret-server.hkn"

paths_to_try = [
    "/flag", "/keycheck", "/next_chars", "/", "/magic-key", "/index.css",
    "http://magic-key.hkn/flag", "http://magic-key.hkn/", "http://magic-key.hkn/keycheck",
    "magic-key.hkn", "magic-key.hkn/flag",
]

for p in paths_to_try:
    print(f"\n### URL header = {p!r} ###")
    for char in ["s", "p", "a"]:
        r = requests.get(f"http://{SS}/next_chars", params={"char": char},
                          headers={"Host": HOST, "URL": p}, timeout=4)
        print(f"  char={char} -> {r.status_code}: {r.text.strip()[:150]}")
