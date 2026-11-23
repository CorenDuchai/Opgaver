#!/usr/bin/env python3
import requests, time

MAGIC = "magic-key.hkn"
DECOY = "dGhpcyB0b2tlbiBpcyBub3QgZ29vZA"

headers = {"Session-Token": DECOY, "URL-Maybe": "/flag"}

for trigger_char in ["d", "s", "a"]:
    print(f"\n### Repeated char='{trigger_char}' query against magic-key.hkn/next_chars, 40 times, same session ###")
    session = requests.Session()
    seq = []
    for i in range(40):
        r = session.get(f"http://{MAGIC}/next_chars", params={"char": trigger_char}, headers=headers, timeout=4)
        chunk = r.text.strip().strip('"')
        seq.append(chunk)
        time.sleep(0.15)
    print(f"  Sequence: {seq}")
    assembled = "".join(seq)
    print(f"  Assembled (naive concat): {assembled[:200]}")
    # Check for repetition / cycle length
    for cycle_len in range(1, 21):
        if seq[:cycle_len] * (len(seq)//cycle_len + 1) == seq[:len(seq) - (len(seq) % cycle_len) or len(seq)][:len(seq)]:
            pass
    # simpler: find first repeat of an identical element to estimate randomness
    first_repeat_at = None
    for i in range(1, len(seq)):
        if seq[i] == seq[0]:
            first_repeat_at = i
            break
    print(f"  First repeat of seq[0] ({seq[0]!r}) at index: {first_repeat_at}")
    unique_count = len(set(seq))
    print(f"  Unique responses in 40 calls: {unique_count}")
