pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Hyprland options changed in the Settings app (Windows, Effects, Keyboard & mouse pages).
// Each change applies at once through `hyprctl eval 'hl.config(...)'`; the changed options are kept
// in settings.json (Settings.hypr, "general.gaps_in" → 5) and written as Lua to
// ~/.local/state/pikadots/hypr-settings.lua, which hypr/settings.lua loads after its own values.
// Keys starting with "pikadots." are handled here: animation speed, workspace animation, cursor.
Singleton {
    id: root

    readonly property string luaPath: Quickshell.env("HOME") + "/.local/state/pikadots/hypr-settings.lua"

    // Option → current value, read from Hyprland (refresh()) and updated as things change
    property var values: ({})
    property bool ready: false
    property var cursorThemes: []

    // Options shown in the app, with the value type hyprctl reports
    readonly property var keys: [
        "general.gaps_in", "general.gaps_out", "general.border_size", "general.layout", "general.resize_on_border",
        "decoration.rounding", "decoration.rounding_power", "decoration.active_opacity", "decoration.inactive_opacity",
        "decoration.dim_inactive", "decoration.dim_strength", "decoration.blur.enabled", "decoration.blur.size",
        "decoration.blur.passes", "decoration.blur.vibrancy", "decoration.shadow.enabled", "decoration.shadow.range",
        "animations.enabled",
        "input.kb_layout", "input.kb_options", "input.repeat_rate", "input.repeat_delay", "input.sensitivity",
        "input.accel_profile", "input.follow_mouse", "input.natural_scroll", "input.touchpad.natural_scroll",
        "input.touchpad.tap_to_click", "input.touchpad.disable_while_typing", "input.touchpad.scroll_factor"
    ]

    // hypr/settings.lua's animations, which the speed setting scales
    readonly property var animations: [
        { leaf: "windows", speed: 3 },
        { leaf: "workspaces", speed: 5 },
        { leaf: "fade", speed: 3 },
        { leaf: "specialWorkspace", speed: 2, style: "slidefadevert" }
    ]
    readonly property var defaults: ({
        "pikadots.animationSpeed": 1,
        "pikadots.workspaceStyle": "slide",
        "pikadots.cursorTheme": "Bibata-Modern-Ice",
        "pikadots.cursorSize": 28
    })

    property var pending: ({})

    // The bar's workspace indicator uses animations.enabled before the app is ever opened
    Component.onCompleted: refresh()

    function value(key) {
        return Settings.hypr[key] ?? values[key] ?? defaults[key];
    }

    function changed(key) {
        return Settings.hypr[key] !== undefined;
    }

    function set(key, v) {
        if (value(key) === v)
            return;
        const saved = Object.assign({}, Settings.hypr);
        saved[key] = v;
        Settings.hypr = saved;
        const now = Object.assign({}, values);
        now[key] = v;
        values = now;
        pending[key] = v;
        applyTimer.restart();
    }

    // Forgets the changes to `keys` and reloads Hyprland so its own config's values come back
    function reset(keys) {
        const saved = Object.assign({}, Settings.hypr);
        for (const k of keys)
            delete saved[k];
        Settings.hypr = saved;
        writeLua();
        if (keys.some(k => k.startsWith("pikadots.cursor")))
            applyCursor();
        Quickshell.execDetached(["hyprctl", "reload"]);
        refreshTimer.restart();
    }

    function refresh() {
        reader.running = true;
        cursorReader.running = true;
    }

    // { "general.gaps_in": 5 } → general = { gaps_in = 5 }
    function luaTable(map) {
        const tree = {};
        for (const [path, v] of Object.entries(map)) {
            if (path.startsWith("pikadots."))
                continue;
            const parts = path.split(".");
            let node = tree;
            for (const p of parts.slice(0, -1))
                node = node[p] = node[p] ?? {};
            node[parts[parts.length - 1]] = v;
        }
        const encode = v => {
            if (typeof v === "object")
                return "{ " + Object.entries(v).map(([k, x]) => (/^[A-Za-z_]\w*$/.test(k) ? k : `["${k}"]`) + " = " + encode(x)).join(", ") + " }";
            if (typeof v === "string")
                return JSON.stringify(v);
            return String(v);
        };
        return Object.keys(tree).length ? encode(tree) : "";
    }

    function animationLua(map) {
        const speed = map["pikadots.animationSpeed"] ?? defaults["pikadots.animationSpeed"];
        const style = map["pikadots.workspaceStyle"] ?? defaults["pikadots.workspaceStyle"];
        return animations.map(a => {
            const s = a.leaf === "workspaces" ? style : a.style;
            return `hl.animation({ leaf = "${a.leaf}", enabled = true, speed = ${Math.max(0.5, a.speed * speed).toFixed(1)}, bezier = "default"${s ? `, style = "${s}"` : ""} })`;
        });
    }

    function writeLua() {
        const map = Settings.hypr;
        const lines = ["-- Written by the Settings app (quickshell/Hypr.qml); loaded at the end of hypr/settings.lua"];
        const table = luaTable(map);
        if (table)
            lines.push(`hl.config(${table})`);
        if (map["pikadots.animationSpeed"] !== undefined || map["pikadots.workspaceStyle"] !== undefined)
            lines.push(...animationLua(map));
        if (map["pikadots.cursorTheme"] !== undefined || map["pikadots.cursorSize"] !== undefined) {
            lines.push(`hl.env("XCURSOR_THEME", ${JSON.stringify(value("pikadots.cursorTheme"))})`);
            lines.push(`hl.env("XCURSOR_SIZE", "${value("pikadots.cursorSize")}")`);
        }
        luaFile.setText(lines.join("\n") + "\n");
    }

    function applyCursor() {
        const theme = value("pikadots.cursorTheme");
        const size = String(value("pikadots.cursorSize"));
        Quickshell.execDetached(["sh", "-c", 'hyprctl setcursor "$1" "$2" >/dev/null; '
            + 'gsettings set org.gnome.desktop.interface cursor-theme "$1"; gsettings set org.gnome.desktop.interface cursor-size "$2"',
            "sh", theme, size]);
    }

    Timer {
        id: applyTimer
        interval: 60
        onTriggered: {
            const batch = root.pending;
            root.pending = {};
            const table = root.luaTable(batch);
            const script = [];
            if (table)
                script.push(`hl.config(${table})`);
            if ("pikadots.animationSpeed" in batch || "pikadots.workspaceStyle" in batch)
                script.push(...root.animationLua(Settings.hypr));
            if (script.length)
                Quickshell.execDetached(["hyprctl", "eval", script.join("; ")]);
            if ("pikadots.cursorTheme" in batch || "pikadots.cursorSize" in batch)
                root.applyCursor();
            root.writeLua();
        }
    }

    Timer {
        id: refreshTimer
        interval: 600
        onTriggered: root.refresh()
    }

    Process {
        id: reader
        command: ["sh", "-c", 'for k in "$@"; do hyprctl -j getoption "$(echo "$k" | tr . :)"; echo; done', "sh", ...root.keys]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    if (!line.trim().startsWith("{"))
                        continue;
                    try {
                        const o = JSON.parse(line);
                        const key = o.option.replace(/:/g, ".");
                        let v = o.int ?? o.float ?? o.bool ?? o.str ?? o.css;
                        if (o.css !== undefined)
                            v = parseInt(o.css);
                        if (o.float !== undefined)
                            v = Math.round(o.float * 1000) / 1000;
                        if (v === "[[EMPTY]]")
                            v = "";
                        out[key] = v;
                    } catch (e) {}
                }
                root.values = out;
                root.ready = true;
            }
        }
    }

    // Cursor themes: icon theme folders with a cursors/ directory
    Process {
        id: cursorReader
        command: ["sh", "-c", 'for d in "$HOME"/.icons/*/cursors "$HOME"/.local/share/icons/*/cursors /usr/share/icons/*/cursors; do [ -d "$d" ] && basename "$(dirname "$d")"; done | sort -fu']
        stdout: StdioCollector {
            onStreamFinished: root.cursorThemes = text.split("\n").filter(t => t)
        }
    }

    FileView {
        id: luaFile
        path: root.luaPath
        printErrors: false
    }
}
