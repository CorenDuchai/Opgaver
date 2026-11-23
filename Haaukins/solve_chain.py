#!/usr/bin/env python3
# Rekonstruerer den skjulte streng fra /next_chars sliding-window-graf

edges = {
    'b': ["SUA"],
    'd': [":C%"],
    'k': ["0"],
    'p': ["wd:"],
    's': ["52s", "I@$"],
    'u': ["k0"],
    'w': ["d:C"],
    'A': ["s52"],
    'C': ["%{6"],
    'I': ["@$K"],
    'K': ["8Ou"],
    'O': ["uk0"],
    'S': ["UAs"],
    'U': ["As5"],
    '0': [""],
    '2': ["sI@"],
    '5': ["2sI"],
    '6': ["bSU"],
    '8': ["Ouk"],
    '@': ["$K8"],
    '$': ["K8O"],
    '%': ["{6b"],
    ':': ["C%{"],
    '{': ["6bS"],
}

def walk(start_char, max_steps=200):
    if start_char not in edges or not edges[start_char][0]:
        return None
    window = edges[start_char][0]
    master = start_char + window
    visited = set()
    for _ in range(max_steps):
        next_char = window[0]
        key = (next_char, window)
        if key in visited:
            master += " <CYCLE DETECTED, stopper> "
            break
        visited.add(key)
        if next_char not in edges:
            break
        candidates = edges[next_char]
        # Vaelg den kandidat hvis forste 2 tegn matcher vindues sidste 2 tegn (overlap-regel)
        chosen = None
        for cand in candidates:
            if len(cand) >= 2 and cand[:2] == window[1:3]:
                chosen = cand
                break
        if chosen is None:
            if len(candidates) == 1:
                chosen = candidates[0]
            else:
                master += f" <FLERTYDIG VED '{next_char}': {candidates}> "
                break
        if chosen == "":
            # Slut naaet (fx '0' -> "")
            break
        master += chosen[-1]
        window = chosen
    return master

print("=== Start fra 'p' ===")
print(walk('p'))

print()
print("=== Start fra 'b' (alternativ start) ===")
print(walk('b'))

print()
print("=== Start fra 's' - foelger forste gren (52s) ===")
edges_s1 = dict(edges)
edges_s1['s'] = ["52s"]
def walk2(start_char, e, max_steps=50):
    if start_char not in e:
        return None
    window = e[start_char][0]
    master = start_char + window
    for _ in range(max_steps):
        next_char = window[0]
        if next_char not in e:
            break
        cands = e[next_char]
        chosen = cands[0] if len(cands)==1 else next((c for c in cands if c[:2]==window[1:3]), cands[0])
        if chosen == "":
            break
        master += chosen[-1]
        window = chosen
        if len(master) > 40:
            master += " <for lang, stopper> "
            break
    return master
print(walk2('s', edges_s1))

print()
print("=== Start fra 's' - foelger anden gren (I@$) ===")
edges_s2 = dict(edges)
edges_s2['s'] = ["I@$"]
print(walk2('s', edges_s2))
