pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/default-apps.py"
    readonly property var roleNames: ["browser", "files", "editor", "terminal"]
    property var roles: ({})
    property var apps: ({})

    function idFor(role) {
        return Object.keys(roles).find(id => roles[id] === role) ?? "";
    }

    function roleOf(id) {
        return roles[id] ?? "";
    }

    function load() {
        lister.poll();
    }

    function set(kind, id) {
        const next = Object.assign({}, apps);
        next[kind] = Object.assign({}, next[kind], { current: id });
        apps = next;
        setter.command = ["python3", "-I", script, "set", kind, id];
        setter.running = true;
    }

    function detect() {
        detector.running = true;
    }

    Component.onCompleted: detect()

    JsonPoll {
        id: lister
        command: ["python3", "-I", root.script, "list"]
        onLoaded: json => root.apps = json
    }

    Process {
        id: setter
        onExited: {
            root.load();
            root.detect();
        }
    }

    Process {
        id: detector
        command: ["sh", "-c", "printf '%s\\n' \"$(xdg-settings get default-web-browser 2>/dev/null)\" \"$(xdg-mime query default inode/directory 2>/dev/null)\" \"$(xdg-mime query default text/plain 2>/dev/null)\" \"$(grep -v '^#' \"${XDG_CONFIG_HOME:-$HOME/.config}/xdg-terminals.list\" 2>/dev/null | head -n1)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(l => l.trim().replace(/\.desktop$/, ""));
                const r = {};
                root.roleNames.forEach((n, i) => {
                    const id = lines[i] || (n === "terminal" ? (Quickshell.env("TERMINAL") || "kitty").replace(/^.*\//, "") : "");
                    if (id && !r[id])
                        r[id] = n;
                });
                root.roles = r;
            }
        }
    }
}
