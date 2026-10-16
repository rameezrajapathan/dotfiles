pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.bar
import qs.overlays

Singleton {
    id: root

    property var shown: ({})

    signal opened(string monitor, string name)

    readonly property var known: ({
        magic: { label: "Scratchpad 1", key: "Super + F1", icon: "stack" },
        magic1: { label: "Scratchpad 2", key: "Super + F2", icon: "stack" },
        dropterm: { label: "Terminal", key: "Super + `", icon: "terminal" },
        background: { label: "Background apps", key: "", icon: "inventory_2" }
    })

    function on(monitor) {
        return shown[monitor] ?? "";
    }

    function info(name) {
        return known[name] ?? { label: name.charAt(0).toUpperCase() + name.slice(1), key: "", icon: "stack" };
    }

    function hide(name) {
        if (name)
            Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.workspace.toggle_special("${name}")`]);
    }

    function set(monitor, name) {
        if ((shown[monitor] ?? "") === name)
            return;
        const s = Object.assign({}, shown);
        s[monitor] = name;
        shown = s;
        if (name)
            opened(monitor, name);
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activespecialv2")
                return;
            const parts = event.data.split(",");
            const monitor = parts.pop();
            const name = parts.slice(1).join(",").replace(/^special:/, "");
            root.set(monitor, name);
        }
    }

    Process {
        running: true
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = {};
                    for (const m of JSON.parse(text))
                        s[m.name] = (m.specialWorkspace?.name ?? "").replace(/^special:/, "");
                    root.shown = s;
                } catch (e) {}
            }
        }
    }
}
