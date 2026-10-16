pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar
import qs.lock

Singleton {
    id: root

    readonly property var groups: [
        { title: "Apps & system", icon: "apps", pattern: /^Open|launcher|clipboard|Lock|power|wallpaper|keybind|notification|Disturb|terminal|color|project/i },
        { title: "Screenshots & recording", icon: "screenshot_region", pattern: /screenshot|record|capture/i },
        { title: "Media & hardware", icon: "graphic_eq", pattern: /volume|mute|media|track|brightness/i },
        { title: "Workspaces & monitors", icon: "space_dashboard", pattern: /workspace|monitor/i },
        { title: "Windows", icon: "select_window", pattern: /./ }
    ]

    property var binds: []

    function refresh() {
        reader.running = true;
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
        for (const b of JSON.parse(json)) {
            if (!b.has_description || b.submap !== "" || b.key === "" || b.key.startsWith("switch:"))
                continue;
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
        binds = rows.map(r => ({
            desc: r.desc,
            keys: r.mods.concat([r.alts.join(" / ")]),
            group: groups.find(g => g.pattern.test(r.desc)).title
        }));
    }

    Process {
        id: reader
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.load(text)
        }
    }
}
