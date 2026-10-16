#!/usr/bin/env python3
"""Wallpaper colors for VS Code, Code - OSS and VSCodium, through a small "Pikadots" theme extension.

The extension only holds a color theme (matugen template vscode-theme.json). Its themes are
contributed with VS Code's `_watch` flag, so editors reload the file when it changes and follow
each wallpaper live. Light and dark follow the desktop's color-scheme (window.autoDetectColorScheme,
which theme.sh sets through gsettings).

  vscode-theme.py           copy the generated theme into every installed copy of the extension
  vscode-theme.py install   build and install the extension in each editor found, and select it
  vscode-theme.py restore   put each editor's previous theme back and remove the extension
"""

import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

HOME = os.path.expanduser("~")
THEME = os.path.join(HOME, ".local/state/theme/vscode-theme.json")
STATE = os.path.join(HOME, ".local/state/pikadots")

PUBLISHER, NAME, VERSION = "pikadots", "pikadots-theme", "1.0.0"
EXT_ID = f"{PUBLISHER}.{NAME}"
DARK, LIGHT = "Pikadots Dark", "Pikadots Light"

# name, command, user settings folder, extensions folder. Code - OSS and VSCodium share extensions.
EDITORS = [
    ("Code - OSS", "code-oss", ".config/Code - OSS/User", ".vscode-oss/extensions"),
    ("VS Code", "code", ".config/Code/User", ".vscode/extensions"),
    ("VSCodium", "codium", ".config/VSCodium/User", ".vscode-oss/extensions"),
]

PACKAGE = {
    "name": NAME,
    "displayName": "Pikadots",
    "description": "Colors from the wallpaper, made by the pikadots desktop (matugen)",
    "publisher": PUBLISHER,
    "version": VERSION,
    "engines": {"vscode": "^1.70.0"},
    "categories": ["Themes"],
    # Both read the same generated file; the base (vs / vs-dark) is what changes
    "contributes": {
        "themes": [
            {"label": DARK, "uiTheme": "vs-dark", "path": "./themes/pikadots.json", "_watch": True},
            {"label": LIGHT, "uiTheme": "vs", "path": "./themes/pikadots.json", "_watch": True},
        ],
        # The tint under the transparent window (--vscode-pikadots-glass, see GLASS_CSS)
        "colors": [
            {
                "id": "pikadots.glass",
                "description": "See-through background of the transparent Code - OSS window",
                "defaults": {"dark": "#131314d9", "light": "#f8f9fad9", "highContrast": "#000000"},
            }
        ],
    },
}

MANIFEST = f"""<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="{NAME}" Version="{VERSION}" Publisher="{PUBLISHER}"/>
    <DisplayName>Pikadots</DisplayName>
    <Description xml:space="preserve">{PACKAGE["description"]}</Description>
    <Categories>Themes</Categories>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="{PACKAGE["engines"]["vscode"]}"/>
    </Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/>
  </Assets>
</PackageManifest>
"""

CONTENT_TYPES = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension=".json" ContentType="application/json"/>
  <Default Extension=".vsixmanifest" ContentType="text/xml"/>
</Types>
"""


def generated():
    try:
        with open(THEME) as f:
            return f.read()
    except OSError:
        return None


def mode():
    try:
        return json.loads(generated() or "{}").get("type", "dark")
    except ValueError:
        return "dark"


def editors():
    """The editors whose command is installed, with absolute paths."""
    found = []
    for name, cmd, user, exts in EDITORS:
        path = shutil.which(cmd)
        if not path:
            continue
        # Arch's Code - OSS also installs `code` (a link to code-oss); that's not Microsoft's
        if cmd == "code" and os.path.basename(os.path.realpath(path)).startswith("code-oss"):
            continue
        found.append((name, path, os.path.join(HOME, user), os.path.join(HOME, exts)))
    return found


# settings.json is JSON with comments and trailing commas, and holds the user's own settings, so
# only the few keys below are touched, in place, keeping everything else as written
VALUE = r'"(?:[^"\\]|\\.)*"|true|false|null|-?[\d.]+|\{[^{}]*\}'


def read_setting(text, key):
    m = re.search(r'"%s"\s*:\s*(%s)' % (re.escape(key), VALUE), text)
    return json.loads(m.group(1)) if m else None


def write_setting(text, key, value):
    """Sets key to value (None removes it)."""
    pattern = r'(\n[ \t]*)?"%s"\s*:\s*(?:%s)\s*,?' % (re.escape(key), VALUE)
    if value is None:
        return re.sub(pattern, "", text, count=1)
    new = '"%s": %s' % (key, json.dumps(value))
    if re.search(pattern, text):
        return re.sub(r'"%s"\s*:\s*(?:%s)' % (re.escape(key), VALUE), lambda _: new, text, count=1)
    indent = re.search(r'\n([ \t]+)"', text)
    indent = indent.group(1) if indent else "  "
    if "{" not in text:
        text = "{\n}\n"
    return text.replace("{", "{\n%s%s," % (indent, new), 1)


def mono_font():
    """Settings > Fonts' terminal font, which kitty uses too."""
    try:
        with open(os.path.join(HOME, ".config/pikadots/settings.json")) as f:
            return json.load(f).get("appearance", {}).get("monoFont")
    except (OSError, ValueError):
        return None


def settings_keys():
    keys = {
        "workbench.colorTheme": LIGHT if mode() == "light" else DARK,
        "workbench.preferredDarkColorTheme": DARK,
        "workbench.preferredLightColorTheme": LIGHT,
        "window.autoDetectColorScheme": True,
        # Like kitty: block cursor that blinks softly and glides, padding around the text
        "editor.cursorStyle": "block",
        "editor.cursorBlinking": "smooth",
        "editor.cursorSmoothCaretAnimation": "on",
        "terminal.integrated.cursorStyle": "block",
        "editor.padding": {"top": 12, "bottom": 12},
    }
    font = mono_font()
    if font:
        keys["editor.fontFamily"] = font
        keys["terminal.integrated.fontFamily"] = font
    return keys


def update_settings(user_dir, slug):
    path = os.path.join(user_dir, "settings.json")
    try:
        with open(path) as f:
            text = f.read()
    except FileNotFoundError:
        text = "{\n}\n"
    keys = settings_keys()
    # The values from before we first set each key, for restore
    backup = os.path.join(STATE, f"vscode-{slug}.json")
    try:
        with open(backup) as f:
            saved = json.load(f)
    except (OSError, ValueError):
        saved = {}
    if any(k not in saved for k in keys):
        for k in keys:
            saved.setdefault(k, read_setting(text, k))
        os.makedirs(STATE, exist_ok=True)
        with open(backup, "w") as f:
            json.dump(saved, f, indent=2)
    new = text
    for k, v in keys.items():
        new = write_setting(new, k, v)
    if new != text:
        os.makedirs(user_dir, exist_ok=True)
        with open(path, "w") as f:  # in place, so a linked settings.json stays linked
            f.write(new)


def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def apply():
    theme = generated()
    if theme is None:
        return
    for themes in glob.glob(os.path.join(HOME, ".vscode*/extensions", f"{EXT_ID}-*", "themes")):
        target = os.path.join(themes, "pikadots.json")
        try:
            with open(target) as f:
                if f.read() == theme:
                    continue
        except OSError:
            pass
        # Truncate and write the same file: the editors watch this path
        with open(target, "w") as f:
            f.write(theme)
    # Light or dark for editors that don't follow the desktop, and the font from Settings > Fonts,
    # in the editors we were installed in (those have a backup)
    for name, _, user_dir, _ in editors():
        if os.path.exists(os.path.join(STATE, f"vscode-{slug(name)}.json")):
            update_settings(user_dir, slug(name))
    glass()


# Code - OSS runs on the system Electron from a small launcher (/usr/lib/code/code.mjs), so a copy
# of that launcher can open its windows transparent, like kitty's background_opacity: the window
# is see-through, the parts are made clear and one tint (pikadots.glass) is painted under them.
# Text stays solid; Hyprland blurs what's behind. Microsoft's VS Code bundles its own Electron and
# stays opaque.
SYSTEM_LAUNCHER = "/usr/lib/code/code.mjs"
SYSTEM_SCRIPT = "/usr/bin/code-oss"
SYSTEM_DESKTOP = "/usr/share/applications/code-oss.desktop"
GLASS_LAUNCHER = os.path.join(HOME, ".local/share/pikadots/code-oss/code.mjs")
GLASS_SCRIPT = os.path.join(HOME, ".local/bin/code-oss")
GLASS_CODE = os.path.join(HOME, ".local/bin/code")
GLASS_DESKTOP = os.path.join(HOME, ".local/share/applications/code-oss.desktop")
MARK = "pikadots: transparent Code - OSS"

CLEAR = """editor-background editorGutter-background minimap-background editorOverviewRuler-background
breadcrumb-background editorGroupHeader-tabsBackground editorGroupHeader-noTabsBackground
editorGroup-emptyBackground titleBar-activeBackground titleBar-inactiveBackground
activityBar-background sideBar-background sideBarSectionHeader-background panel-background
panelSectionHeader-background outputView-background auxiliaryBar-background statusBar-background
statusBar-noFolderBackground terminal-background welcomePage-background""".split()

GLASS_CSS = (
    "html, body { background: transparent !important; }\n"
    ".monaco-workbench {\n  background-color: var(--vscode-pikadots-glass) !important;\n"
    + "".join(f"  --vscode-{v}: transparent !important;\n" for v in CLEAR)
    + "}\n"
    # The parts also get the editor color as an inline style, which only a user !important beats
    ".monaco-workbench .part, .monaco-workbench .part > .content,\n"
    ".monaco-workbench .editor-group-container > .title, .monaco-workbench .editor-container {\n"
    "  background-color: transparent !important;\n}\n"
)

PRELUDE = """// %s (made by hypr/scripts/vscode-theme.py from %s)
import { createRequire as pikadotsRequire, registerHooks as pikadotsHooks } from "node:module";
{
  const electron = pikadotsRequire(import.meta.url)("electron");
  const Base = electron.BrowserWindow;
  // Electron tells windows apart by this class name
  const Glass = class BrowserWindow extends Base {
    constructor(options = {}) {
      super({ ...options, transparent: true, backgroundColor: "#00000000" });
    }
    setBackgroundColor() {
      super.setBackgroundColor("#00000000");
    }
  };
  // electron's exports can't be replaced, so `import ... from "electron"` gets a copy with Glass
  globalThis.pikadotsGlass = { electron, Glass };
  const names = Object.keys(electron).filter((k) => /^[A-Za-z_$][\\w$]*$/.test(k) && k !== "BrowserWindow");
  const source = "const { electron: e, Glass } = globalThis.pikadotsGlass;\\n" +
    "export default Object.create(e, { BrowserWindow: { value: Glass, enumerable: true } });\\n" +
    "export const BrowserWindow = Glass;\\n" +
    names.map((k) => `export const ${k} = e.${k};`).join("\\n");
  pikadotsHooks({
    resolve: (specifier, context, next) =>
      specifier === "electron" ? { url: "pikadots:electron", shortCircuit: true } : next(specifier, context),
    load: (url, context, next) =>
      url === "pikadots:electron" ? { format: "module", source, shortCircuit: true } : next(url, context),
  });
  const css = %s;
  electron.app.on("web-contents-created", (_, contents) => {
    contents.on("dom-ready", () => {
      if (contents.getType() === "window") contents.insertCSS(css, { cssOrigin: "user" }).catch(() => {});
    });
  });
}
"""


def write_if_changed(path, text, mode=0o644):
    try:
        with open(path) as f:
            if f.read() == text:
                return
    except OSError:
        pass
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)
    os.chmod(path, mode)


def ours(path):
    try:
        with open(path) as f:
            return MARK in f.read()
    except OSError:
        return False


def glass():
    """Writes the transparent launcher, `code-oss`/`code` in ~/.local/bin and the menu entry.
    Called on every apply, so a Code - OSS update is picked up."""
    try:
        with open(SYSTEM_LAUNCHER) as f:
            launcher = f.read()
        with open(SYSTEM_SCRIPT) as f:
            script = f.read()
    except OSError:
        return
    if "import.meta.dirname" not in launcher or SYSTEM_LAUNCHER not in script:
        print("Code - OSS's launcher changed; it stays opaque", file=sys.stderr)
        return
    # It finds the app (and package.json) next to itself; the copy points at the real folder
    launcher = launcher.replace("import.meta.dirname", json.dumps(os.path.dirname(SYSTEM_LAUNCHER)))
    launcher = launcher.replace("import.meta.url", json.dumps("file://" + SYSTEM_LAUNCHER))
    shebang = ""
    if launcher.startswith("#!"):
        shebang, launcher = launcher.split("\n", 1)
        shebang += "\n"
    prelude = PRELUDE % (MARK, SYSTEM_LAUNCHER, json.dumps(GLASS_CSS))
    write_if_changed(GLASS_LAUNCHER, shebang + prelude + launcher)
    script = script.replace("#!/bin/bash\n", "#!/bin/bash\n# %s\n" % MARK, 1)
    write_if_changed(GLASS_SCRIPT, script.replace(SYSTEM_LAUNCHER, GLASS_LAUNCHER), 0o755)
    if not os.path.lexists(GLASS_CODE):
        os.symlink("code-oss", GLASS_CODE)
    try:
        with open(SYSTEM_DESKTOP) as f:
            desktop = f.read()
        desktop = re.sub(r"^Exec=code-oss", "Exec=" + GLASS_SCRIPT, desktop, flags=re.M)
        write_if_changed(GLASS_DESKTOP, desktop.replace("[Desktop Entry]\n", "[Desktop Entry]\n# %s\n" % MARK, 1))
    except OSError:
        pass


def unglass():
    for path in (GLASS_DESKTOP, GLASS_SCRIPT, GLASS_LAUNCHER):
        if ours(path):
            os.remove(path)
    if os.path.islink(GLASS_CODE) and os.readlink(GLASS_CODE) == "code-oss":
        os.remove(GLASS_CODE)


def install():
    found = editors()
    if not found:
        print("no VS Code, Code - OSS or VSCodium found")
        return 0
    with tempfile.TemporaryDirectory() as tmp:
        vsix = os.path.join(tmp, f"{EXT_ID}-{VERSION}.vsix")
        with zipfile.ZipFile(vsix, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr("[Content_Types].xml", CONTENT_TYPES)
            z.writestr("extension.vsixmanifest", MANIFEST)
            z.writestr("extension/package.json", json.dumps(PACKAGE, indent=2))
            z.writestr("extension/themes/pikadots.json", generated() or '{"name": "Pikadots"}')
        failed = 0
        for name, cmd, user_dir, _ in found:
            r = subprocess.run([cmd, "--install-extension", vsix, "--force"], capture_output=True, text=True)
            if r.returncode != 0:
                print(f"{name}: {(r.stderr or r.stdout).strip()}", file=sys.stderr)
                failed += 1
                continue
            update_settings(user_dir, slug(name))
            print(f"{name} uses the wallpaper colors")
    apply()
    return 1 if failed else 0


def restore():
    for name, cmd, user_dir, _ in editors():
        backup = os.path.join(STATE, f"vscode-{slug(name)}.json")
        path = os.path.join(user_dir, "settings.json")
        if os.path.exists(backup) and os.path.exists(path):
            with open(backup) as f:
                previous = json.load(f)
            with open(path) as f:
                text = f.read()
            for k, v in previous.items():
                text = write_setting(text, k, v)
            with open(path, "w") as f:
                f.write(text)
            os.remove(backup)
        subprocess.run([cmd, "--uninstall-extension", EXT_ID], capture_output=True)
        print(f"{name}: previous theme restored")
    unglass()
    return 0


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "apply"
    if cmd == "install":
        sys.exit(install())
    elif cmd == "restore":
        sys.exit(restore())
    elif cmd == "apply":
        apply()
    else:
        sys.exit(__doc__)
