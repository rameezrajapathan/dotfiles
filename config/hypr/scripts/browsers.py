#!/usr/bin/env python3
import configparser
import glob
import html.parser
import json
import os
import shlex
import sqlite3
import subprocess
import sys
import time
import urllib.parse
import urllib.request

HOME = os.path.expanduser("~")
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config")
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.join(HOME, ".cache"), "pikadots", "favicons")
WEB = "x-scheme-handler/https"

CHROMIUM = {
    "google-chrome": "google-chrome",
    "google-chrome-stable": "google-chrome",
    "google-chrome-beta": "google-chrome-beta",
    "google-chrome-unstable": "google-chrome-unstable",
    "chromium": "chromium",
    "chromium-browser": "chromium",
    "brave": "BraveSoftware/Brave-Browser",
    "brave-browser": "BraveSoftware/Brave-Browser",
    "microsoft-edge": "microsoft-edge",
    "microsoft-edge-stable": "microsoft-edge",
    "microsoft-edge-beta": "microsoft-edge-beta",
    "vivaldi": "vivaldi",
    "vivaldi-stable": "vivaldi",
    "thorium-browser": "thorium",
    "helium": "net.imput.helium",
}

FIREFOX = {
    "firefox": [".config/mozilla/firefox", ".mozilla/firefox"],
    "firefox-esr": [".config/mozilla/firefox", ".mozilla/firefox"],
    "firefox-developer-edition": [".config/mozilla/firefox", ".mozilla/firefox"],
    "zen": [".config/zen", ".zen"],
    "zen-bin": [".config/zen", ".zen"],
    "zen-browser": [".config/zen", ".zen"],
    "librewolf": [".config/librewolf/librewolf", ".librewolf"],
    "floorp": [".config/floorp", ".floorp"],
    "waterfox": [".config/waterfox", ".waterfox"],
}


def app_dirs():
    data_home = os.environ.get("XDG_DATA_HOME") or os.path.join(HOME, ".local/share")
    data_dirs = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
    return [os.path.join(d, "applications") for d in [data_home] + data_dirs.split(":")]


def entries():
    found = {}
    for base in app_dirs():
        for root, _, files in os.walk(base):
            for name in files:
                if not name.endswith(".desktop"):
                    continue
                path = os.path.join(root, name)
                entry_id = os.path.relpath(path, base).replace("/", "-")
                if entry_id in found:
                    continue
                parser = configparser.RawConfigParser(strict=False, interpolation=None)
                try:
                    parser.read(path, encoding="utf-8")
                    e = parser["Desktop Entry"]
                except Exception:
                    found[entry_id] = None
                    continue
                if e.get("Type") != "Application" or e.get("Hidden") == "true":
                    found[entry_id] = None
                    continue
                found[entry_id] = {
                    "id": entry_id,
                    "name": e.get("Name", entry_id),
                    "icon": e.get("Icon", ""),
                    "exec": e.get("Exec", ""),
                    "hidden": e.get("NoDisplay") == "true",
                    "mime": [m for m in e.get("MimeType", "").split(";") if m],
                }
    return {k: v for k, v in found.items() if v}


def command(entry):
    try:
        argv = shlex.split(entry["exec"])
    except ValueError:
        return []
    argv = [a for a in argv if not (len(a) == 2 and a.startswith("%"))]
    if argv and argv[0] == "env":
        argv = argv[1:]
        while argv and "=" in argv[0]:
            argv = argv[1:]
    return argv


def binary(entry):
    argv = command(entry)
    if not argv:
        return ""
    if os.path.basename(argv[0]) == "flatpak":
        app = next((a for a in argv[1:] if "." in a and not a.startswith("-")), "")
        return {"com.google.Chrome": "google-chrome", "org.chromium.Chromium": "chromium", "com.brave.Browser": "brave",
                "org.mozilla.firefox": "firefox", "app.zen_browser.zen": "zen"}.get(app, "")
    return os.path.basename(argv[0])


def default_browser():
    try:
        return subprocess.run(["xdg-settings", "get", "default-web-browser"], capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return ""


def argb(value):
    if not isinstance(value, int):
        return ""
    return "#%06x" % (value & 0xFFFFFF)


def chromium_profiles(folder):
    root = os.path.join(CONFIG, folder)
    try:
        with open(os.path.join(root, "Local State"), encoding="utf-8") as f:
            cache = json.load(f).get("profile", {}).get("info_cache", {})
    except (OSError, ValueError):
        return []
    out = []
    for pid, info in cache.items():
        picture = os.path.join(root, pid, info.get("gaia_picture_file_name") or "Google Profile Picture.png")
        out.append({
            "id": pid,
            "name": info.get("name") or info.get("gaia_name") or pid,
            "detail": info.get("user_name") or pid,
            "color": argb(info.get("profile_highlight_color", info.get("default_avatar_fill_color"))),
            "picture": picture if os.path.isfile(picture) else "",
        })
    return sorted(out, key=lambda p: (p["id"] != "Default", p["id"]))


def firefox_root(candidates):
    for rel in candidates:
        root = os.path.join(HOME, rel)
        if os.path.isfile(os.path.join(root, "profiles.ini")):
            return root
    return ""


def group_themes(root):
    themes = {}
    for db in glob.glob(os.path.join(root, "Profile Groups", "*.sqlite")):
        try:
            con = sqlite3.connect("file:" + urllib.parse.quote(db) + "?mode=ro&immutable=1", uri=True, timeout=1)
            for path, name, bg in con.execute("select path, name, themeBg from Profiles"):
                themes[os.path.normpath(os.path.join(root, path))] = {"name": name, "color": bg or ""}
            con.close()
        except sqlite3.Error:
            pass
    return themes


def firefox_profiles(candidates):
    root = firefox_root(candidates)
    if not root:
        return []
    ini = configparser.RawConfigParser(strict=False, interpolation=None)
    try:
        ini.read(os.path.join(root, "profiles.ini"), encoding="utf-8")
    except Exception:
        return []
    installed = {ini[s].get("Default") for s in ini.sections() if s.startswith("Install")}
    themes = group_themes(root)
    out = []
    for s in ini.sections():
        if not s.startswith("Profile"):
            continue
        p = ini[s]
        rel = p.get("Path", "")
        if not rel:
            continue
        full = os.path.normpath(os.path.join(root, rel) if p.get("IsRelative", "1") == "1" else rel)
        theme = themes.get(full, {})
        out.append({
            "id": full,
            "name": theme.get("name") or p.get("Name") or os.path.basename(full),
            "detail": os.path.basename(full) + (" · in use" if rel in installed else ""),
            "color": theme.get("color", ""),
            "picture": "",
        })
    return sorted(out, key=lambda p: (" · in use" not in p["detail"], p["name"].lower()))


def browser_info(entry):
    b = binary(entry)
    if b in CHROMIUM:
        return "chromium", chromium_profiles(CHROMIUM[b])
    if b in FIREFOX:
        return "firefox", firefox_profiles(FIREFOX[b])
    return "other", []


def browsers():
    apps = entries()
    default = default_browser()
    seen = {}
    for e in sorted(apps.values(), key=lambda e: (e["id"] != default, e["hidden"], e["name"].lower())):
        if WEB not in e["mime"] and e["id"] != default:
            continue
        key = binary(e) or e["id"]
        if key in seen:
            continue
        family, profiles = browser_info(e)
        seen[key] = {"id": e["id"], "name": e["name"], "icon": e["icon"], "family": family, "profiles": profiles}
    return {"default": default, "browsers": sorted(seen.values(), key=lambda b: b["name"].lower())}


def notify(title, body):
    subprocess.Popen(["notify-send", "-a", "Shortcuts", "-i", "dialog-warning", title, body],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def spawn(argv):
    subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     start_new_session=True, cwd=HOME)


def open_default(url):
    spawn([os.path.join(os.path.dirname(os.path.realpath(__file__)), "app.sh"), "browser", url])


def open_url(browser_id, profile, url):
    if not browser_id:
        open_default(url)
        return
    apps = entries()
    entry = apps.get(browser_id)
    argv = command(entry) if entry else []
    if not argv:
        notify("Browser not found", f"{browser_id.removesuffix('.desktop')} isn't installed, so this opened in your default browser.")
        open_default(url)
        return
    if profile:
        family, profiles = browser_info(entry)
        if not any(p["id"] == profile for p in profiles):
            notify("Profile not found", f"That {entry['name']} profile is gone, so this opened in its usual profile.")
        elif family == "chromium":
            argv.append("--profile-directory=" + profile)
        elif family == "firefox":
            argv += ["--profile", profile]
    spawn(argv + [url])


class IconLinks(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []

    def handle_starttag(self, tag, attrs):
        if tag != "link":
            return
        a = dict(attrs)
        rel = (a.get("rel") or "").lower().split()
        if a.get("href") and ("icon" in rel or "apple-touch-icon" in rel):
            size = 0
            for s in (a.get("sizes") or "").lower().split():
                try:
                    size = max(size, int(s.split("x")[0]))
                except ValueError:
                    pass
            if "apple-touch-icon" in rel and not size:
                size = 180
            if (a.get("type") or "").endswith("svg") or a["href"].lower().split("?")[0].endswith(".svg"):
                size = 1000
            self.links.append((size, a["href"]))


def fetch(url, limit=1 << 20):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) pikadots-shortcuts"})
    with urllib.request.urlopen(req, timeout=6) as r:
        return r.geturl(), r.headers.get_content_type(), r.read(limit)


EXT = {"image/png": "png", "image/x-icon": "ico", "image/vnd.microsoft.icon": "ico", "image/svg+xml": "svg",
       "image/jpeg": "jpg", "image/webp": "webp", "image/gif": "gif"}


def favicon(url):
    if "://" not in url:
        url = "https://" + url
    host = urllib.parse.urlsplit(url).hostname or ""
    if not host:
        return ""
    os.makedirs(CACHE, exist_ok=True)
    for f in glob.glob(os.path.join(CACHE, glob.escape(host) + ".*")):
        if not f.endswith(".none"):
            return f
        if time.time() - os.path.getmtime(f) < 7 * 86400:
            return ""
    candidates = []
    try:
        final, kind, body = fetch(url, 512 * 1024)
        if kind == "text/html":
            p = IconLinks()
            p.feed(body.decode("utf-8", "replace"))
            candidates += [urllib.parse.urljoin(final, h) for _, h in sorted(p.links, reverse=True)]
    except Exception:
        final = url
    origin = urllib.parse.urlunsplit(urllib.parse.urlsplit(final)[:2] + ("", "", ""))
    candidates += [origin + "/apple-touch-icon.png", origin + "/favicon.ico"]
    for c in candidates:
        try:
            _, kind, data = fetch(c)
        except Exception:
            continue
        ext = EXT.get(kind)
        if not ext and data[:4] == b"\x89PNG":
            ext = "png"
        if not ext and data[:4] == b"\x00\x00\x01\x00":
            ext = "ico"
        if ext and len(data) > 64:
            path = os.path.join(CACHE, host + "." + ext)
            with open(path, "wb") as f:
                f.write(data)
            return path
    open(os.path.join(CACHE, host + ".none"), "w").close()
    return ""


def main():
    args = sys.argv[1:]
    if args == ["list"]:
        json.dump(browsers(), sys.stdout)
    elif len(args) == 4 and args[0] == "open":
        open_url(args[1], args[2], args[3])
    elif len(args) == 2 and args[0] == "favicon":
        print(favicon(args[1]))
    else:
        sys.exit("usage: browsers.py list | open BROWSER_ID PROFILE_ID URL | favicon URL")


main()
