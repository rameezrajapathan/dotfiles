pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var monitors: []
    property var saved: ({})
    readonly property var enabled: monitors.filter(m => !m.disabled)
    readonly property bool external: enabled.some(m => !isLaptop(m))
    readonly property var scales: [1, 1.25, 1.33, 1.5, 1.6, 2]
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/pikadots"

    function refresh() {
        query.running = true;
    }

    function isLaptop(m) {
        return /^(eDP|LVDS|DSI)/.test(m.name);
    }

    function resolutions(m) {
        return [...new Set(m.availableModes.map(mode => mode.split("@")[0]))]
            .sort((a, b) => pixels(b) - pixels(a));
    }
    function rates(m, resolution) {
        return m.availableModes.filter(mode => mode.startsWith(resolution + "@"))
            .sort((a, b) => parseFloat(b.split("@")[1]) - parseFloat(a.split("@")[1]));
    }
    function pixels(resolution) {
        const [w, h] = resolution.split("x").map(Number);
        return w * h;
    }

    function current(m) {
        const rule = Object.assign({}, saved[m.description] ?? {});
        delete rule.disabled;
        if (m.disabled)
            return Object.assign({ mode: "preferred", position: "auto", scale: 1 }, rule);
        return Object.assign({
            mode: `${m.width}x${m.height}@${m.refreshRate.toFixed(2)}Hz`,
            position: `${m.x}x${m.y}`,
            scale: Math.round(m.scale * 100) / 100,
            cm: m.colorManagementPreset
        }, rule);
    }

    function set(m, changes) {
        const rule = Object.assign(current(m), changes);
        for (const key in rule)
            if (rule[key] === undefined)
                delete rule[key];
        const next = Object.assign({}, saved);
        next[m.description] = rule;
        saved = next;
        save();
        Quickshell.execDetached(["hyprctl", "eval", lua(m.description, rule)]);
        refreshTimer.restart();
    }

    function reset(m) {
        const next = Object.assign({}, saved);
        delete next[m.description];
        saved = next;
        save();
        Quickshell.execDetached(["hyprctl", "reload"]);
        refreshTimer.restart();
    }

    function lua(description, rule) {
        const fields = [`output = ${JSON.stringify("desc:" + description)}`];
        if (rule.disabled) {
            fields.push("disabled = true");
        } else {
            for (const key of ["mode", "position", "scale", "cm", "mirror"])
                if (rule[key] !== undefined)
                    fields.push(`${key} = ${typeof rule[key] === "number" ? rule[key] : JSON.stringify(rule[key])}`);
        }
        return `hl.monitor({ ${fields.join(", ")} })`;
    }

    function save() {
        jsonFile.setText(JSON.stringify(saved, null, 2) + "\n");
        const lines = ["-- Written by Quickshell's display panel (Displays.qml); loaded by hypr/monitors.lua"];
        for (const description in saved)
            lines.push(lua(description, saved[description]));
        luaFile.setText(lines.join("\n") + "\n");
    }

    Process {
        id: query
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text).sort((a, b) => a.x - b.x || a.id - b.id);
                } catch (err) {}
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 600
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (/^monitor(added|removed)/.test(event.name))
                refreshTimer.restart();
        }
    }

    FileView {
        id: jsonFile
        path: root.stateDir + "/monitors.json"
        printErrors: false
        onLoaded: {
            try {
                root.saved = JSON.parse(text());
            } catch (err) {
                root.saved = {};
            }
        }
    }

    FileView {
        id: luaFile
        path: root.stateDir + "/monitors.lua"
        printErrors: false
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", stateDir]);
        refresh();
    }
}
