pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Special workspaces (Hyprland's scratchpads that open over the current workspace): which one is
// shown on each monitor, with a name and the key that hides it. The bar's workspace indicator
// turns into a chip while one is open (SpecialChip.qml), SpecialToast.qml names it as it opens,
// and hypr/rules.lua gives its windows a border in Theme.special.
Singleton {
    id: root

    // Monitor name → shown special workspace without "special:" ("" for none)
    property var shown: ({})

    signal opened(string monitor, string name)

    // Names and keys of the ones the keybinds use (hypr/keybinds.lua)
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

    // activespecialv2>>ID,NAME,MONITOR (ID and NAME empty when it closes)
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

    // What's shown when the shell starts
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
