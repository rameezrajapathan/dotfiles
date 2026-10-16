#!/usr/bin/env python3
import configparser, json, os, re

DIRS = [os.path.expanduser("~/.local/share/icons"), os.path.expanduser("~/.icons"), "/usr/share/icons"]
SKIP = {"hicolor", "locolor", "default", "AdwaitaLegacy"}
CONCEPTS = [
    ["folder", "inode-directory"],
    ["utilities-terminal", "org.gnome.Terminal", "kitty", "terminal"],
    ["firefox", "web-browser", "internet-web-browser", "zen-browser"],
    ["preferences-system", "systemsettings", "org.gnome.Settings", "settings"],
    ["accessories-text-editor", "org.gnome.TextEditor", "text-editor", "gedit"],
    ["multimedia-video-player", "vlc", "totem", "org.gnome.Totem", "applications-multimedia"],
    ["image-viewer", "org.gnome.Loupe", "eog", "gwenview", "multimedia-photo-viewer"],
    ["utilities-system-monitor", "org.gnome.SystemMonitor", "gnome-system-monitor", "htop"],
]
VARIANT = re.compile(r"[-_](dark|light|Dark|Light)$")

def themes():
    found = {}
    for base in DIRS:
        if not os.path.isdir(base):
            continue
        for name in sorted(os.listdir(base)):
            path = os.path.join(base, name)
            index = os.path.join(path, "index.theme")
            if name in SKIP or name in found or not os.path.isfile(index):
                continue
            cp = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                cp.read(index)
                dirs = cp.get("Icon Theme", "Directories", fallback="").strip()
            except configparser.Error:
                continue
            if dirs:
                found[name] = path
    return found

def score(path):
    m = re.search(r"/(\d+)(?:x\d+)?(?:@\d+x)?/", path)
    if "scalable" in path or "/symbolic/" in path:
        return 1 if "symbolic" not in path else 9
    if m:
        return abs(int(m.group(1)) - 48) / 16 + (0 if int(m.group(1)) >= 32 else 5)
    return 5

def samples(paths):
    index, symbolic = {}, {}
    for root in paths:
        for dirpath, _, files in os.walk(root, followlinks=True):
            for f in files:
                stem, ext = os.path.splitext(f)
                if ext not in (".svg", ".png"):
                    continue
                p = os.path.join(dirpath, f)
                if stem.endswith("-symbolic"):
                    symbolic.setdefault(stem[:-9], p)
                elif stem not in index or score(p) < score(index[stem]):
                    index[stem] = p
    out = []
    for names in CONCEPTS:
        hit = next((index[n] for n in names if n in index and os.path.exists(index[n])), None) \
            or next((symbolic[n] for n in names if n in symbolic), None)
        if hit:
            out.append(hit)
    return out

CACHE = os.path.expanduser("~/.cache/pikadots/icon-themes.json")

def main():
    stamp = max((os.path.getmtime(d) for d in DIRS if os.path.isdir(d)), default=0)
    if os.path.exists(CACHE) and os.path.getmtime(CACHE) > stamp:
        with open(CACHE) as f:
            print(f.read())
        return
    all_themes = themes()
    families = {}
    for name in all_themes:
        family = VARIANT.sub("", name)
        families.setdefault(family, []).append(name)
    result = []
    for family, variants in sorted(families.items(), key=lambda kv: kv[0].lower()):
        dirs = [all_themes[v] for v in sorted(variants, key=lambda v: v != family)]
        s = samples(dirs)
        if len(s) >= 3:
            result.append({"family": family, "variants": sorted(variants), "samples": s})
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE, "w") as f:
        json.dump(result, f)
    print(json.dumps(result))

main()
