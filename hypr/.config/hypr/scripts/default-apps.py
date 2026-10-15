#!/usr/bin/env python3
"""Default apps for the Settings app (Default apps page).

  default-apps.py list         JSON: {kind: {"current": id, "options": [{"id", "name", "icon"}]}}
  default-apps.py set KIND ID  makes ID (a desktop entry id) the default for KIND

Terminal uses ~/.config/xdg-terminals.list (xdg-terminal-exec, scripts/app.sh); browser uses
xdg-settings; the rest are xdg-mime defaults for the kind's file types.
"""
import configparser
import json
import os
import subprocess
import sys

KINDS = {
    "browser": ["x-scheme-handler/https", "x-scheme-handler/http", "text/html"],
    "files": ["inode/directory"],
    "editor": ["text/plain"],
    "images": ["image/png", "image/jpeg", "image/webp", "image/gif"],
    "video": ["video/mp4", "video/x-matroska", "video/webm"],
    "music": ["audio/mpeg", "audio/flac", "audio/ogg"],
    "pdf": ["application/pdf"],
    "mail": ["x-scheme-handler/mailto"],
}
TERMINALS = os.path.expanduser("~/.config/xdg-terminals.list")


def app_dirs():
    data_home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    data_dirs = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
    return [os.path.join(d, "applications") for d in [data_home] + data_dirs.split(":")]


def entries():
    """Visible desktop entries by id; user entries win, like the desktop does."""
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
                    continue
                if e.get("Type") != "Application":
                    found[entry_id] = None
                    continue
                found[entry_id] = {
                    # Hidden ones aren't offered, but name a default that is one (web app shortcuts)
                    "hidden": e.get("NoDisplay") == "true" or e.get("Hidden") == "true",
                    "id": entry_id,
                    "name": e.get("Name", entry_id),
                    "icon": e.get("Icon", ""),
                    "mime": [m for m in e.get("MimeType", "").split(";") if m],
                    "categories": [c for c in e.get("Categories", "").split(";") if c],
                }
                if found[entry_id]["hidden"] and e.get("Hidden") == "true":
                    found[entry_id] = None
    return {k: v for k, v in found.items() if v}


def run(*cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return ""


def current_terminal():
    try:
        with open(TERMINALS) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    return line.split(":")[0]
    except OSError:
        pass
    return ""


def option(e):
    return {"id": e["id"], "name": e["name"], "icon": e["icon"]}


def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "list":
        apps = entries()
        out = {
            "terminal": {
                "current": current_terminal(),
                "options": sorted((option(e) for e in apps.values() if not e["hidden"] and "TerminalEmulator" in e["categories"]), key=lambda o: o["name"].lower()),
            }
        }
        for kind, mimes in KINDS.items():
            current = run("xdg-settings", "get", "default-web-browser") if kind == "browser" else run("xdg-mime", "query", "default", mimes[0])
            options = [option(e) for e in apps.values() if not e["hidden"] and mimes[0] in e["mime"]]
            # A default that doesn't list the type (or a renamed entry) still shows as chosen
            if current and current in apps and all(o["id"] != current for o in options):
                options.append(option(apps[current]))
            out[kind] = {"current": current, "options": sorted(options, key=lambda o: o["name"].lower())}
        json.dump(out, sys.stdout)
    elif len(sys.argv) == 4 and sys.argv[1] == "set":
        kind, entry_id = sys.argv[2], sys.argv[3]
        if kind == "terminal":
            rest = []
            if os.path.exists(TERMINALS):
                with open(TERMINALS) as f:
                    rest = [l.rstrip("\n") for l in f if l.strip() and l.split(":")[0].strip() != entry_id]
            with open(TERMINALS, "w") as f:
                f.write("\n".join([entry_id] + rest) + "\n")
        elif kind == "browser":
            run("xdg-settings", "set", "default-web-browser", entry_id)
            run("xdg-mime", "default", entry_id, *KINDS["browser"])
        elif kind in KINDS:
            run("xdg-mime", "default", entry_id, *KINDS[kind])
        else:
            sys.exit(f"unknown kind {kind}")
    else:
        sys.exit(__doc__)


main()
