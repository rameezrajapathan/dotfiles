#!/usr/bin/env python3
import configparser
import math
import os
import re
import shutil
import subprocess
import sys
import time

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from pikadots_common import HOME, load_json, settings_section

COLORS = os.path.join(HOME, ".local/state/theme/quickshell.json")
CACHE = os.path.join(HOME, ".local/state/pikadots/folder-color")
ICON_DIRS = [os.path.join(HOME, ".icons"), os.path.join(HOME, ".local/share/icons"), "/usr/local/share/icons", "/usr/share/icons"]
OVERLAY_DIR = os.path.join(HOME, ".local/share/icons")
MARKER = ".pikadots-folders"
THEMES = ["Papirus-Light", "Papirus", "Papirus-Dark"]
SIZES = ["22x22", "24x24", "32x32", "48x48", "64x64"]
PALETTE = {
    "blue": "#5294e2",
    "bluegrey": "#607d8b",
    "breeze": "#57b8ec",
    "brown": "#ae8e6c",
    "cyan": "#00bcd4",
    "darkcyan": "#45abb7",
    "deeporange": "#eb6637",
    "green": "#87b158",
    "grey": "#8e8e8e",
    "indigo": "#5c6bc0",
    "magenta": "#ca71df",
    "nordic": "#81a1c1",
    "orange": "#ee923a",
    "palebrown": "#d1bfae",
    "paleorange": "#eeca8f",
    "pink": "#f06292",
    "red": "#e25252",
    "teal": "#16a085",
    "violet": "#7e57c2",
    "yellow": "#f9bd30",
}

def oklab(hex_color):
    h = hex_color.lstrip("#")
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(int(h[i : i + 2], 16)) for i in (0, 2, 4))
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    )

def lch(hex_color):
    _, a, b = oklab(hex_color)
    return math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360

def nearest(accent, available):
    chroma, hue = lch(accent)
    if chroma < 0.025 and "grey" in available:
        return "grey"
    def distance(name):
        c, h = lch(PALETTE[name])
        turn = abs(hue - h) % 360
        return min(turn, 360 - turn) + 120 * abs(min(chroma, 0.15) - c)
    return min((n for n in PALETTE if n in available and n != "grey"), key=distance)

def theme_dirs():
    found = []
    for name in THEMES:
        for base in ICON_DIRS:
            path = os.path.join(base, name)
            if os.path.isfile(os.path.join(path, "index.theme")) and not os.path.exists(os.path.join(path, MARKER)):
                found.append((name, path))
                break
    return found

def available(path):
    places = os.path.join(path, "48x48/places")
    try:
        names = os.listdir(places)
    except OSError:
        return set()
    return {n[len("folder-") : -len("-documents.svg")] for n in names if n.startswith("folder-") and n.endswith("-documents.svg")}

def current(path):
    colors = set()
    for size in SIZES:
        link = os.path.join(path, size, "places/folder.svg")
        if os.path.exists(link):
            colors.add(os.path.basename(os.path.realpath(link))[len("folder-") : -len(".svg")])
    return colors

def writable(path):
    return os.access(os.path.realpath(os.path.join(path, "48x48/places")), os.W_OK)

def place_dirs(path):
    cp = configparser.ConfigParser(interpolation=None, strict=False)
    try:
        cp.read(os.path.join(path, "index.theme"))
    except configparser.Error:
        return []
    dirs = []
    for key in ("Directories", "ScaledDirectories"):
        for d in cp.get("Icon Theme", key, fallback="").split(","):
            d = d.strip()
            if d.endswith("/places") and d not in dirs and os.path.isdir(os.path.join(path, d)):
                dirs.append(d)
    return dirs

COLORED = re.compile(r"^(folder|user)-(" + "|".join(sorted(PALETTE, key=len, reverse=True)) + r")(-.*)?\.svg$")

def overlay(name, path, color):
    root = os.path.join(OVERLAY_DIR, name)
    if os.path.exists(root) and not os.path.exists(os.path.join(root, MARKER)):
        return
    os.makedirs(root, exist_ok=True)
    open(os.path.join(root, MARKER), "w").close()
    index = os.path.join(root, "index.theme")
    if os.path.realpath(index) != os.path.realpath(os.path.join(path, "index.theme")):
        if os.path.lexists(index):
            os.remove(index)
        os.symlink(os.path.join(path, "index.theme"), index)
    for entry in os.listdir(root):
        full = os.path.join(root, entry)
        if os.path.isdir(full) and not os.path.islink(full):
            shutil.rmtree(full)
    for d in place_dirs(path):
        src = os.path.join(path, d)
        dst = os.path.join(root, d)
        for f in os.listdir(src):
            if not f.endswith(".svg") or COLORED.match(f):
                continue
            real = os.path.realpath(os.path.join(src, f))
            m = COLORED.match(os.path.basename(real))
            if not m:
                continue
            target = os.path.join(os.path.dirname(real), f"{m.group(1)}-{color}{m.group(3) or ''}.svg")
            if not os.path.isfile(target):
                continue
            os.makedirs(dst, exist_ok=True)
            os.symlink(target, os.path.join(dst, f))
    os.utime(root)

def refresh():
    if shutil.which("gsettings"):
        key = ["org.gnome.desktop.interface", "icon-theme"]
        got = subprocess.run(["gsettings", "get", *key], capture_output=True, text=True)
        theme = got.stdout.strip()
        if got.returncode == 0 and theme:
            subprocess.run(["gsettings", "set", *key, "''"], capture_output=True)
            time.sleep(0.3)
            subprocess.run(["gsettings", "set", *key, theme], capture_output=True)
    if shutil.which("gdbus"):
        emit = ["gdbus", "emit", "--session", "--object-path"]
        subprocess.run([*emit, "/KIconLoader", "--signal", "org.kde.KIconLoader.iconChanged", "0"], capture_output=True)
        time.sleep(0.2)
        subprocess.run([*emit, "/KGlobalSettings", "--signal", "org.kde.KGlobalSettings.notifyChange", "0", "0"], capture_output=True)

def main():
    args = sys.argv[1:]
    dry = "--dry-run" in args
    force = "--force" in args
    appearance = settings_section("appearance")
    accent = next((a for a in args if a.startswith("#")), None) or load_json(COLORS).get("accent")
    if not accent:
        sys.exit("folders: no accent color yet; run theme.sh")
    themes = theme_dirs()
    if not themes:
        sys.exit("folders: Papirus is not installed")
    color = nearest(accent, available(themes[0][1]) or set(PALETTE))
    if dry:
        print(color)
        for name, path in themes:
            shown = path if writable(path) else os.path.join(OVERLAY_DIR, name)
            state = "ok" if current(shown) == {color} else "change"
            print(f"{name} {path} {state} {'papirus-folders' if writable(path) else 'overlay'}")
        return
    if not appearance.get("folderAccent", False):
        return
    if not str(appearance.get("iconTheme") or "Papirus").startswith("Papirus"):
        return
    tool = shutil.which("papirus-folders")
    try:
        with open(CACHE, encoding="utf-8") as f:
            last = f.read().strip()
    except OSError:
        last = ""
    if last == color and not force:
        return
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE, "w", encoding="utf-8") as f:
        f.write(color + "\n")
    for name, path in themes:
        if writable(path):
            if tool and current(path) != {color}:
                subprocess.run([tool, "-C", color, "-t", name], stdin=subprocess.DEVNULL, capture_output=True)
        else:
            overlay(name, path, color)
    refresh()

if __name__ == "__main__":
    main()
