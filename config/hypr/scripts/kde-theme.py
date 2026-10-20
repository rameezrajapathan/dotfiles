#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import tempfile

HOME = os.path.expanduser("~")
KDEGLOBALS = os.path.join(HOME, ".config/kdeglobals")
COLORS = os.path.join(HOME, ".local/state/theme/kde.json")
SETTINGS = os.path.join(HOME, ".config/pikadots/settings.json")
BACKUP = os.path.join(HOME, ".local/state/pikadots/kdeglobals-plasma.json")
SCHEME = os.path.join(HOME, ".local/share/color-schemes/Pikadots.colors")
ICONS = os.path.join(HOME, ".config/hypr/scripts/icons.sh")
KCMINPUTRC = os.path.join(HOME, ".config/kcminputrc")
CURSOR_KEYS = ["cursorTheme", "cursorSize"]

SECTIONS = [
    "Colors:Button",
    "Colors:Complementary",
    "Colors:Header",
    "Colors:Header][Inactive",
    "Colors:Selection",
    "Colors:Tooltip",
    "Colors:View",
    "Colors:Window",
    "WM",
]
KEYS = {
    "General": ["ColorScheme", "AccentColor", "font", "fixed", "smallestReadableFont", "toolBarFont", "menuFont"],
    "Icons": ["Theme"],
    "KDE": ["AnimationDurationFactor"],
}
MARKER = ("General", "PikadotsApplied")

def read_ini(path):
    sections = [["", []]]
    try:
        with open(path, encoding="utf-8") as f:
            for line in f.read().splitlines():
                if line.startswith("[") and line.endswith("]"):
                    sections.append([line[1:-1], []])
                elif "=" in line:
                    key, value = line.split("=", 1)
                    sections[-1][1].append([key, value])
    except FileNotFoundError:
        pass
    return sections

def write_ini(path, sections):
    out = []
    for name, entries in sections:
        if name == "":
            out += [f"{k}={v}" for k, v in entries]
            continue
        if not entries:
            continue
        if out:
            out.append("")
        out.append(f"[{name}]")
        out += [f"{k}={v}" for k, v in entries]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix="." + os.path.basename(path) + ".")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    os.replace(tmp, path)

def section(sections, name, create=False):
    for s in sections:
        if s[0] == name:
            return s[1]
    if not create:
        return None
    sections.append([name, []])
    return sections[-1][1]

def get_key(sections, name, key):
    entries = section(sections, name) or []
    for k, v in entries:
        if k == key:
            return v
    return None

def set_key(sections, name, key, value):
    entries = section(sections, name, create=value is not None)
    if entries is None:
        return
    for i, (k, _) in enumerate(entries):
        if k == key:
            if value is None:
                del entries[i]
            else:
                entries[i][1] = value
            return
    if value is not None:
        entries.append([key, value])

def set_section(sections, name, entries):
    existing = section(sections, name)
    if entries is None:
        sections[:] = [s for s in sections if s[0] != name]
    elif existing is None:
        sections.append([name, [list(e) for e in entries]])
    else:
        existing[:] = [list(e) for e in entries]

def snapshot(sections):
    return {
        "sections": {n: section(sections, n) for n in SECTIONS},
        "keys": {s: {k: get_key(sections, s, k) for k in keys} for s, keys in KEYS.items()},
        "kcminputrc": cursor_snapshot(),
    }

def cursor_snapshot():
    sections = read_ini(KCMINPUTRC)
    return {k: get_key(sections, "Mouse", k) for k in CURSOR_KEYS}

def cursor_settings():
    try:
        with open(SETTINGS, encoding="utf-8") as f:
            hypr = json.load(f).get("hypr", {})
    except (OSError, ValueError, AttributeError):
        hypr = {}
    return str(hypr.get("pikadots.cursorTheme") or "Bibata-Modern-Ice"), str(hypr.get("pikadots.cursorSize") or 28)

def set_cursor(values):
    sections = read_ini(KCMINPUTRC)
    if all(get_key(sections, "Mouse", k) == v for k, v in values.items()):
        return
    for key, value in values.items():
        set_key(sections, "Mouse", key, value)
    write_ini(KCMINPUTRC, sections)

def put_back(sections, saved):
    for name, entries in saved["sections"].items():
        set_section(sections, name, entries)
    for name, keys in saved["keys"].items():
        for key, value in keys.items():
            set_key(sections, name, key, value)
    set_key(sections, *MARKER, None)

def rgb(hex_color):
    h = hex_color.lstrip("#")
    return ",".join(str(int(h[i : i + 2], 16)) for i in (0, 2, 4))

def mix(a, b, t):
    a, b = a.lstrip("#"), b.lstrip("#")
    return "#" + "".join(
        f"{round(int(a[i:i+2], 16) * (1 - t) + int(b[i:i+2], 16) * t):02x}" for i in (0, 2, 4)
    )

def is_light(hex_color):
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i : i + 2], 16) / 255 for i in (0, 2, 4))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b > 0.5

def color_sections(c):
    def colorset(bg, alt, fg=c["on_surface"], inactive=c["on_surface_variant"]):
        return [
            ["BackgroundAlternate", rgb(alt)],
            ["BackgroundNormal", rgb(bg)],
            ["DecorationFocus", rgb(c["primary"])],
            ["DecorationHover", rgb(c["primary"])],
            ["ForegroundActive", rgb(c["primary"])],
            ["ForegroundInactive", rgb(inactive)],
            ["ForegroundLink", rgb(c["primary"])],
            ["ForegroundNegative", rgb(c["error"])],
            ["ForegroundNeutral", rgb(c["yellow"])],
            ["ForegroundNormal", rgb(fg)],
            ["ForegroundPositive", rgb(c["green"])],
            ["ForegroundVisited", rgb(c["tertiary"])],
        ]

    selection = colorset(
        c["primary"], c["primary_container"], fg=c["on_primary"], inactive=mix(c["on_primary"], c["primary"], 0.3)
    )
    for entry in selection:
        if entry[0] in ("ForegroundActive", "ForegroundLink", "ForegroundVisited"):
            entry[1] = rgb(c["on_primary"])
    return {
        "Colors:Button": colorset(c["surface_container_high"], c["surface_container_highest"]),
        "Colors:Complementary": colorset(c["surface_container_lowest"], c["surface_container_low"]),
        "Colors:Header": colorset(c["surface_container"], c["surface_container_high"]),
        "Colors:Header][Inactive": colorset(c["surface"], c["surface_container"]),
        "Colors:Selection": selection,
        "Colors:Tooltip": colorset(c["surface_container_highest"], c["surface_container_high"]),
        "Colors:View": colorset(c["surface_container_low"], c["surface_container"]),
        "Colors:Window": colorset(c["surface"], c["surface_container_low"]),
        "WM": [
            ["activeBackground", rgb(c["surface_container"])],
            ["activeBlend", rgb(c["on_surface"])],
            ["activeForeground", rgb(c["on_surface"])],
            ["inactiveBackground", rgb(c["surface"])],
            ["inactiveBlend", rgb(c["on_surface_variant"])],
            ["inactiveForeground", rgb(c["on_surface_variant"])],
        ],
    }

def qt_font(family, size=10):
    return f"{family},{size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

def load_settings():
    try:
        with open(SETTINGS, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError):
        data = {}
    return dict(data.get("appearance", {}), **{"a11y": data.get("accessibility", {})})

def notify():
    run = lambda *a: subprocess.run(["gdbus", "emit", "--session", *a], capture_output=True)
    run("--object-path", "/kdeglobals", "--signal", "org.kde.kconfig.notify.ConfigChanged",
        "{'General': [b'ColorScheme', b'font', b'fixed'], 'Icons': [b'Theme'], 'KDE': [b'AnimationDurationFactor']}")
    for change in (0,):
        run("--object-path", "/KGlobalSettings", "--signal", "org.kde.KGlobalSettings.notifyChange",
            str(change), "0")
    run("--object-path", "/KIconLoader", "--signal", "org.kde.KIconLoader.iconChanged", "0")
    run("--object-path", "/kcminputrc", "--signal", "org.kde.kconfig.notify.ConfigChanged",
        "{'Mouse': [b'cursorTheme', b'cursorSize']}")
    run("--object-path", "/KGlobalSettings", "--signal", "org.kde.KGlobalSettings.notifyChange", "5", "0")

def restore():
    sections = read_ini(KDEGLOBALS)
    if get_key(sections, *MARKER) != "true":
        return
    try:
        with open(BACKUP, encoding="utf-8") as f:
            saved = json.load(f)
    except (OSError, ValueError):
        saved = None
    if saved:
        put_back(sections, saved)
        if "kcminputrc" in saved:
            set_cursor(saved["kcminputrc"])
    else:
        set_key(sections, *MARKER, None)
    write_ini(KDEGLOBALS, sections)

def apply():
    settings = load_settings()
    if settings.get("qtTheme", True) is False:
        restore()
        notify()
        return
    try:
        with open(COLORS, encoding="utf-8") as f:
            colors = json.load(f)
    except (OSError, ValueError):
        sys.exit(f"kde-theme: no colors yet ({COLORS}); run theme.sh")

    sections = read_ini(KDEGLOBALS)
    if get_key(sections, *MARKER) == "true":
        with open(BACKUP, encoding="utf-8") as f:
            saved = json.load(f)
        added = False
        for name, keys in KEYS.items():
            for key in keys:
                if key not in saved["keys"].setdefault(name, {}):
                    saved["keys"][name][key] = get_key(sections, name, key)
                    added = True
        if "kcminputrc" not in saved:
            saved["kcminputrc"] = cursor_snapshot()
            added = True
        if added:
            with open(BACKUP, "w", encoding="utf-8") as f:
                json.dump(saved, f, indent=1)
    else:
        saved = snapshot(sections)
        os.makedirs(os.path.dirname(BACKUP), exist_ok=True)
        with open(BACKUP, "w", encoding="utf-8") as f:
            json.dump(saved, f, indent=1)
    put_back(sections, saved)

    generated = color_sections(colors)
    for name, entries in generated.items():
        set_section(sections, name, entries)
    set_key(sections, "General", "ColorScheme", "Pikadots")
    set_key(sections, "General", "AccentColor", None)
    mode = "light" if is_light(colors["surface"]) else "dark"
    icons = subprocess.run([ICONS, "--name", mode], capture_output=True, text=True).stdout.strip()
    if icons:
        set_key(sections, "Icons", "Theme", icons)
    scale = float(settings["a11y"].get("textScale", 1) or 1)
    if settings.get("appFonts") and settings.get("font"):
        for key in ("font", "toolBarFont", "menuFont"):
            set_key(sections, "General", key, qt_font(settings["font"], round(10 * scale)))
        set_key(sections, "General", "smallestReadableFont", qt_font(settings["font"], round(8 * scale)))
        if settings.get("monoFont"):
            set_key(sections, "General", "fixed", qt_font(settings["monoFont"], round(10 * scale)))
    if settings["a11y"].get("reduceMotion"):
        set_key(sections, "KDE", "AnimationDurationFactor", "0")
    set_key(sections, *MARKER, "true")
    write_ini(KDEGLOBALS, sections)
    theme, size = cursor_settings()
    set_cursor({"cursorTheme": theme, "cursorSize": size})

    scheme = [["General", [["ColorScheme", "Pikadots"], ["Name", "Pikadots (wallpaper)"]]]]
    scheme += [[n, e] for n, e in generated.items() if n != "WM"]
    write_ini(SCHEME, scheme)
    notify()

if __name__ == "__main__":
    if sys.argv[1:] == ["restore"]:
        restore()
        notify()
    elif sys.argv[1:]:
        sys.exit("usage: kde-theme.py [restore]")
    else:
        apply()
