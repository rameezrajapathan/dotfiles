pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var shown: ({})

    signal opened(string monitor, string name)

    readonly property var known: ({
        magic: { label: "Scratchpad 1", key: "Super + F1", icon: "stack" },
        magic1: { label: "Scratchpad 2", key: "Super + F2", icon: "stack" },
        dropterm: { label: "Terminal", key: "Super + `", icon: "terminal" },
        minimized: { label: "Minimized", key: "", icon: "minimize" }
    })

    function on(monitor) {
        return shown[monitor] ?? "";
    }

    function info(name) {
        return known[name] ?? { label: name.charAt(0).toUpperCase() + name.slice(1), key: "", icon: "stack" };
    }

    function hide(name) {
        Windows.toggleSpecial(name);
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
            const name = Windows.specialOf(parts.slice(1).join(","));
            root.set(monitor, name);
        }
    }

    JsonPoll {
        running: true
        command: ["hyprctl", "-j", "monitors"]
        onLoaded: json => {
            const s = {};
            for (const m of json)
                s[m.name] = Windows.specialOf(m.specialWorkspace?.name);
            root.shown = s;
        }
        onFailed: error => console.warn("special workspaces: " + error)
    }
}
