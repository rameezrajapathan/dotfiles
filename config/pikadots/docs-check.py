import re
import sys
from pathlib import Path

repo = Path(sys.argv[1])
summary = "--summary" in sys.argv
lua = repo / "config/hypr/keybinds.lua"
doc = repo / "docs/keybindings.md"

MODS = {"super": "SUPER", "shift": "SHIFT", "ctrl": "CTRL", "control": "CTRL", "alt": "ALT"}
NAMES = {
    "`": "grave", ",": "comma", ".": "period", ";": "semicolon", "/": "slash", "?": "slash",
    "[": "bracketleft", "]": "bracketright", "-": "minus", "−": "minus", "=": "equal", "+": "plus",
    "esc": "escape", "enter": "return", "page down": "page_down", "page up": "page_up",
    "left drag": "mouse:272", "right drag": "mouse:273", "rog key": "xf86launch1",
    "volume up": "xf86audioraisevolume", "volume down": "xf86audiolowervolume",
    "mute": "xf86audiomute", "mic mute": "xf86audiomicmute",
    "play": "xf86audioplay", "pause": "xf86audiopause", "next": "xf86audionext",
    "previous": "xf86audioprev", "prev": "xf86audioprev",
    "brightness up": "xf86monbrightnessup", "brightness down": "xf86monbrightnessdown",
    "keyboard backlight up": "xf86kbdbrightnessup", "keyboard backlight down": "xf86kbdbrightnessdown",
}
GROUPS = {
    "arrows": ["left", "right", "up", "down"],
    "scroll": ["mouse_down", "mouse_up"],
}
SKIP_KEYS = re.compile(r"swipe|lid", re.I)
SKIP_SECTIONS = re.compile(r"kitty", re.I)


def combo(mods, key):
    return (tuple(sorted(set(mods))), key)


def show(c):
    mods, key = c
    order = ["SUPER", "CTRL", "ALT", "SHIFT"]
    names = [m.capitalize() for m in sorted(mods, key=order.index)]
    return " + ".join(names + [key.upper() if len(key) == 1 else key])


def lua_binds():
    binds = {}
    for line in lua.read_text().splitlines():
        m = re.match(r'\s*hl\.bind\(([^,]+),', line)
        if not m:
            continue
        desc = re.search(r'description\s*=\s*"([^"]*)"', line)
        if not desc:
            continue
        parts = [p.strip() for p in m.group(1).split("..")]
        variants = [""]
        for p in parts:
            if p == "mod":
                variants = [v + "SUPER" for v in variants]
            elif p == "i":
                variants = [v + str(n) for v in variants for n in range(1, 10)]
            elif p.startswith('"'):
                variants = [v + p.strip('"') for v in variants]
            else:
                variants = []
        text = desc.group(1) + ("1–9" if '" .. i' in line else "")
        for v in variants:
            if v.startswith("switch:"):
                continue
            tokens = [t.strip() for t in v.split("+")]
            mods = [MODS[t.lower()] for t in tokens[:-1] if t.lower() in MODS]
            binds.setdefault(combo(mods, tokens[-1].lower()), text)
    return binds


def key_names(text):
    t = text.strip().replace("\\`", "`").replace("…", "–").lower()
    t = re.sub(r"\s+", " ", t)
    if t in GROUPS:
        return GROUPS[t]
    if t in NAMES:
        return [NAMES[t]]
    m = re.fullmatch(r"(\w)\s*–\s*(\w)", t)
    if m and m.group(1).isdigit():
        return [str(n) for n in range(int(m.group(1)), int(m.group(2)) + 1)]
    if re.fullmatch(r"(\w )+\w", t):
        return t.split(" ")
    return [t]


def expand_slashes(spec):
    alts = [a.strip() for a in spec.split(" / ")]
    out = []
    for i, a in enumerate(alts):
        words = a.split(" ")
        if i > 0 and len(words) == 1 and len(out[-1].split(" ")) > 1 and words[0] in ("up", "down", "pause"):
            a = " ".join(out[-1].split(" ")[:-1] + [a]) if words[0] != "pause" else a
        out.append(a)
    for i in range(len(out) - 1):
        nxt = out[i + 1].split(" ")
        if len(out[i].split(" ")) == 1 and len(nxt) == 2 and nxt[1] == "drag":
            out[i] += " drag"
    return out


def parse_keys(cell):
    combos = []
    last_mods = [[]]
    cell = cell.replace(" or ", ", ")
    for alt in [a.strip() for a in cell.split(", ") if a.strip()]:
        if SKIP_KEYS.search(alt):
            continue
        tokens = [t.strip() for t in alt.split(" + ")]
        mod_sets = [[]]
        for t in tokens[:-1]:
            options = [o.strip().lower() for o in t.split(" / ")]
            if all(o in MODS for o in options):
                mod_sets = [s + [MODS[o]] for s in mod_sets for o in options]
        if len(tokens) == 1:
            mod_sets = last_mods
        else:
            last_mods = mod_sets
        key_spec = tokens[-1]
        if alt.strip().lower() in ("super + ?",):
            mod_sets = [s + ["SHIFT"] for s in mod_sets]
        for spec in expand_slashes(key_spec):
            for name in key_names(spec):
                for mods in mod_sets:
                    combos.append(combo(mods, name))
    return combos


def doc_rows():
    rows = []
    section = ""
    for line in doc.read_text().splitlines():
        if line.startswith("#"):
            section = line.lstrip("# ").strip()
            continue
        if not line.startswith("|") or SKIP_SECTIONS.search(section):
            continue
        cells = [c.strip() for c in re.split(r"(?<!\\)\|", line.strip())[1:-1]]
        if len(cells) < 2 or cells[0] in ("Keys", "") or set(cells[0]) <= set("-: "):
            continue
        combos = parse_keys(cells[0])
        action = cells[1]
        for extra in re.findall(r"\((?:also|or hold) ([^)]*)\)", action):
            combos += parse_keys(extra)
        base = list(combos)
        for mod, _ in re.findall(r"[(;]\s*(?:hold \w+; )?(Shift|Alt|Ctrl)(:| goes)", action):
            combos += [combo(list(m) + [MODS[mod.lower()]], k) for m, k in base]
        last = cells[0].split(" + ")[-1].strip()
        if f"Shift + {last}" in action:
            combos += [combo(list(m) + ["SHIFT"], k) for m, k in list(combos)]
        rows.append((section, cells[0], combos))
    return rows


binds = lua_binds()
rows = doc_rows()
documented = {c for _, _, combos in rows for c in combos}
missing = sorted((c for c in binds if c not in documented), key=show)
stale = [(s, cell, [c for c in combos if c not in binds]) for s, cell, combos in rows]
stale = [(s, cell, bad) for s, cell, bad in stale if bad]

if summary:
    print(f"{len(missing)} {len(stale)}")
    sys.exit(0)

if missing:
    print("Binds in keybinds.lua missing from docs/keybindings.md:")
    for c in missing:
        print(f"  {show(c):32} {binds[c]}")
if stale:
    if missing:
        print()
    print("Doc rows with keys that have no bind:")
    for section, cell, bad in stale:
        print(f"  [{section}] {cell.replace(chr(92), '')}: {', '.join(show(c) for c in bad)}")
if not missing and not stale:
    print(f"docs/keybindings.md matches keybinds.lua ({len(binds)} binds)")
sys.exit(1 if missing or stale else 0)
