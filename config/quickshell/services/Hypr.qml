pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property string luaPath: Quickshell.env("HOME") + "/.local/state/pikadots/hypr-settings.lua"

    property var values: ({})
    property bool ready: false
    property var cursorThemes: []

    readonly property var keys: [
        "general.gaps_in", "general.gaps_out", "general.border_size", "general.layout", "general.resize_on_border",
        "decoration.rounding", "decoration.rounding_power", "decoration.active_opacity", "decoration.inactive_opacity",
        "decoration.dim_inactive", "decoration.dim_strength", "decoration.blur.enabled", "decoration.blur.size",
        "decoration.blur.passes", "decoration.blur.vibrancy", "decoration.blur.variant", "decoration.blur.proportional",
        "decoration.shadow.enabled", "decoration.shadow.range",
        "decoration.wobble.enabled", "decoration.wobble.intensity", "decoration.motion_blur.enabled",
        "animations.enabled", "group.groupbar.disable_when_only", "cursor.hide_on_key_press", "input.swallow_focus_click",
        "misc.animate_mouse_windowdragging", "misc.animate_manual_resizes",
        "decoration.blur.glass.size", "decoration.blur.glass.refraction", "decoration.blur.glass.roughness",
        "decoration.blur.acrylic.clarity", "decoration.blur.acrylic.refraction",
        "decoration.blur.aurora.intensity", "decoration.blur.haze.intensity", "decoration.blur.haze.iridescence",
        "decoration.blur.fluid_jar.fill_amount", "decoration.blur.fluid_jar.turbulence",
        "decoration.blur.ripple.strength", "decoration.blur.ripple.radius", "decoration.blur.ripple.duration",
        "decoration.blur.water.strength", "decoration.blur.water.radius",
        "input.kb_layout", "input.kb_options", "input.repeat_rate", "input.repeat_delay", "input.sensitivity",
        "input.accel_profile", "input.follow_mouse", "input.natural_scroll", "input.touchpad.natural_scroll",
        "input.touchpad.tap_to_click", "input.touchpad.disable_while_typing", "input.touchpad.scroll_factor"
    ]

    readonly property var animations: [
        { leaf: "windows", speed: 3, curved: true },
        { leaf: "windowsIn", speed: 3, curved: true, style: "popin 87%" },
        { leaf: "windowsOut", speed: 1.5, style: "popin 87%" },
        { leaf: "workspaces", speed: 5, curved: true },
        { leaf: "fade", speed: 3 },
        { leaf: "specialWorkspace", speed: 2, curved: true, style: "slidefadevert" }
    ]
    readonly property var reloadKeys: ["pikadots.gestures", "pikadots.backdropColors"]
    readonly property var windowStyles: ({ popin: "popin 87%", slide: "slide", gnomed: "gnomed" })
    readonly property var motionSpeeds: ({
        "decoration.blur.drops.speed": 3,
        "decoration.blur.aurora.speed": 1,
        "decoration.blur.heat_shimmer.speed": 1,
        "decoration.blur.fluid_jar.speed": 3.7
    })
    readonly property bool saving: UPower.onBattery && value("pikadots.pauseOnBattery") !== false
    onSavingChanged: powerTimer.restart()
    readonly property var defaults: ({
        "pikadots.animationSpeed": 1,
        "pikadots.workspaceStyle": "slide",
        "pikadots.motion": "smooth",
        "pikadots.gestures": true,
        "pikadots.windowStyle": "popin",
        "pikadots.borderLoop": false,
        "pikadots.backdropColors": true,
        "pikadots.pauseOnBattery": true,
        "pikadots.cursorTheme": "Bibata-Modern-Ice",
        "pikadots.cursorSize": 28
    })

    readonly property var animationKeys: ["pikadots.animationSpeed", "pikadots.workspaceStyle", "pikadots.motion", "pikadots.windowStyle", "pikadots.borderLoop"]

    property var pending: ({})

    Component.onCompleted: {
        refresh();
        if (saving)
            powerTimer.restart();
    }

    function value(key) {
        if (key in motionSpeeds)
            return Settings.hypr[key] ?? motionSpeeds[key];
        return Settings.hypr[key] ?? values[key] ?? defaults[key];
    }

    function loopLua(on) {
        return ["borderangle", "glowangle"].map(leaf => on
            ? `hl.animation({ leaf = "${leaf}", enabled = true, speed = 60, bezier = "linear", style = "loop" })`
            : `hl.animation({ leaf = "${leaf}", enabled = false })`);
    }

    function powerLua() {
        const speeds = {};
        for (const k of Object.keys(motionSpeeds))
            speeds[k] = saving ? 0 : value(k);
        return [`hl.config(${luaTable(speeds)})`, ...loopLua(!saving && value("pikadots.borderLoop") === true)];
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
        const motion = map["pikadots.motion"] ?? defaults["pikadots.motion"];
        const opening = windowStyles[map["pikadots.windowStyle"] ?? defaults["pikadots.windowStyle"]] ?? "popin 87%";
        const lines = animations.map(a => {
            const s = a.leaf === "workspaces" ? style : a.leaf === "windowsIn" || a.leaf === "windowsOut" ? opening : a.style;
            const curve = a.curved && motion !== "classic" ? `spring = "${motion}"` : `bezier = "default"`;
            return `hl.animation({ leaf = "${a.leaf}", enabled = true, speed = ${Math.max(0.5, a.speed * speed).toFixed(1)}, ${curve}${s ? `, style = "${s}"` : ""} })`;
        });
        return lines.concat(loopLua(map["pikadots.borderLoop"] === true));
    }

    function writeLua() {
        const map = Settings.hypr;
        const lines = ["-- Written by the Settings app (quickshell/Hypr.qml); loaded at the end of hypr/settings.lua"];
        const table = luaTable(map);
        if (table)
            lines.push(`hl.config(${table})`);
        if (map["decoration.blur.proportional"] !== undefined)
            lines.push(`hl.config({ render = { use_shader_blur_blend = ${map["decoration.blur.proportional"]} } })`);
        if (animationKeys.some(k => map[k] !== undefined))
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
        Settings.applyQtTheme();
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
            if (root.animationKeys.some(k => k in batch))
                script.push(...root.animationLua(Settings.hypr));
            if ("decoration.blur.proportional" in batch)
                script.push(`hl.config({ render = { use_shader_blur_blend = ${batch["decoration.blur.proportional"]} } })`);
            if (script.length)
                Quickshell.execDetached(["hyprctl", "eval", script.join("; ")]);
            if ("pikadots.cursorTheme" in batch || "pikadots.cursorSize" in batch)
                root.applyCursor();
            root.writeLua();
            if (root.saving && Object.keys(batch).some(k => k in root.motionSpeeds || k === "pikadots.borderLoop"))
                powerTimer.restart();
            if (root.reloadKeys.some(k => k in batch))
                Quickshell.execDetached(["sh", "-c", "sleep 1; hyprctl reload"]);
        }
    }

    Timer {
        id: powerTimer
        interval: 400
        onTriggered: Quickshell.execDetached(["hyprctl", "eval", root.powerLua().join("; ")])
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && root.saving)
                powerTimer.restart();
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
