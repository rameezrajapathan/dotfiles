pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.bar
import qs.lock

Singleton {
    id: root

    readonly property var groups: [
        { title: "Apps & system", icon: "apps", pattern: /^Open|launcher|clipboard|Lock|power|wallpaper|keybind|notification|Disturb|terminal|color|project|weather|dock/i },
        { title: "Screenshots & recording", icon: "screenshot_region", pattern: /screenshot|record|capture|OCR/i },
        { title: "Media & hardware", icon: "graphic_eq", pattern: /volume|mute|media|track|brightness|zoom/i },
        { title: "Workspaces & monitors", icon: "space_dashboard", pattern: /workspace|monitor/i },
        { title: "Windows", icon: "select_window", pattern: /./ }
    ]

    property var binds: []
    property var entries: []
    property var all: []
    readonly property string luaPath: Quickshell.env("HOME") + "/.local/state/pikadots/keybinds.lua"

    property string fileState: "default"

    function refresh() {
        reader.running = true;
        status.running = true;
    }

    function canon(combo) {
        const order = ["SUPER", "CTRL", "ALT", "SHIFT"];
        const parts = combo.split("+").map(p => p.trim());
        const key = parts.pop() ?? "";
        const mods = parts.map(m => ({ CONTROL: "CTRL", MOD4: "SUPER", WIN: "SUPER" })[m.toUpperCase()] ?? m.toUpperCase());
        mods.sort((a, b) => (order.indexOf(a) + 1 || 9) - (order.indexOf(b) + 1 || 9));
        return mods.concat([key.toLowerCase()]).join(" + ");
    }

    function comboOf(mask, key) {
        return [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]].filter(m => mask & m[0]).map(m => m[1]).concat([key]).join(" + ");
    }

    function owner(combo, except) {
        const id = canon(combo);
        return all.find(b => b.current === id && b.id !== except) ?? null;
    }

    function rebind(id, combo) {
        if (!id)
            return;
        const map = Object.assign({}, Settings.keybinds);
        if (!combo || canon(combo) === id)
            delete map[id];
        else
            map[id] = combo;
        Settings.keybinds = map;
        const lines = ["return {"];
        for (const k of Object.keys(map))
            lines.push(`\t[${JSON.stringify(k)}] = ${JSON.stringify(map[k])},`);
        lines.push("}");
        luaFile.setText(lines.join("\n") + "\n");
        reloadTimer.restart();
    }

    function resetAll() {
        resetter.running = true;
    }

    function record(on) {
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.submap("${on ? "pikadots-record" : "reset"}")`]);
    }

    function keyName(key) {
        const names = {
            Return: "Enter", Escape: "Esc", left: "←", right: "→", up: "↑", down: "↓",
            Page_Up: "PgUp", Page_Down: "PgDn", bracketleft: "[", bracketright: "]",
            minus: "−", equal: "=", slash: "/", question: "?", Print: "PrtSc",
            grave: "`", comma: ",", period: ".", semicolon: ";", apostrophe: "'", backslash: "\\", space: "Space", Tab: "Tab",
            "mouse:272": "Left drag", "mouse:273": "Right drag", mouse_up: "Scroll ↑", mouse_down: "Scroll ↓",
            XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol −", XF86AudioMute: "Mute",
            XF86AudioMicMute: "Mic mute", XF86AudioPlay: "Play", XF86AudioPause: "Pause",
            XF86AudioNext: "Next", XF86AudioPrev: "Prev",
            XF86MonBrightnessUp: "Bright +", XF86MonBrightnessDown: "Bright −",
            XF86KbdBrightnessUp: "Kbd light +", XF86KbdBrightnessDown: "Kbd light −"
        };
        if (key in names)
            return names[key];
        if (key.startsWith("XF86"))
            return key.slice(4).replace(/([a-z])([A-Z0-9])/g, "$1 $2");
        return key.length === 1 ? key.toUpperCase() : key;
    }

    function modNames(mask) {
        const mods = [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]];
        return mods.filter(m => mask & m[0]).map(m => m[1]);
    }

    function load(json) {
        const rows = [];
        const byId = {};
        const original = {};
        for (const k of Object.keys(Settings.keybinds))
            original[canon(Settings.keybinds[k])] = k;
        const list = [];
        const shown = [];
        for (const b of JSON.parse(json)) {
            if (b.submap !== "" || b.key === "")
                continue;
            const current = canon(comboOf(b.modmask, b.key));
            const entry = { id: original[current] ?? current, current: current, desc: b.description };
            list.push(entry);
            if (!b.has_description || b.key.startsWith("switch:"))
                continue;
            shown.push(Object.assign(entry, {
                keys: modNames(b.modmask).concat([keyName(b.key)]),
                changed: entry.id !== current,
                editable: !b.mouse && !b.key.startsWith("mouse"),
                group: groups.find(g => g.pattern.test(b.description)).title
            }));
            let mask = b.modmask;
            let key = keyName(b.key);
            if (b.key === "slash" && mask & 1) {
                key = "?";
                mask &= ~1;
            }
            let desc = b.description;
            if (/^[1-9]$/.test(b.key) && desc.endsWith(" " + b.key)) {
                key = "1 – 9";
                desc = desc.slice(0, -1) + "1–9";
            }
            const id = mask + "|" + desc;
            const row = byId[id];
            if (!row) {
                byId[id] = { mods: modNames(mask), alts: [key], desc: desc };
                rows.push(byId[id]);
            } else if (!row.alts.includes(key)) {
                row.alts.push(key);
            }
        }
        all = list;
        entries = shown;
        binds = rows.map(r => ({
            desc: r.desc,
            keys: r.mods.concat([r.alts.join(" / ")]),
            group: groups.find(g => g.pattern.test(r.desc)).title
        }));
    }

    FileView {
        id: luaFile
        path: root.luaPath
        printErrors: false
    }

    Timer {
        id: reloadTimer
        interval: 300
        onTriggered: Quickshell.execDetached(["hyprctl", "reload"])
    }

    Timer {
        id: refreshTimer
        interval: 700
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                refreshTimer.restart();
        }
    }

    Process {
        id: status
        command: [Quickshell.env("HOME") + "/.local/bin/pikadots", "keybinds", "status"]
        stdout: StdioCollector {
            onStreamFinished: root.fileState = text.trim()
        }
    }

    Process {
        id: resetter
        command: [Quickshell.env("HOME") + "/.local/bin/pikadots", "keybinds", "reset"]
        onExited: refreshTimer.restart()
    }

    Process {
        id: reader
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.load(text)
        }
    }
}
