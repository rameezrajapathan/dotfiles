pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property var list: []

    function refresh() {
        reader.running = true;
    }

    function basename(path) {
        return path.slice(path.lastIndexOf("/") + 1) || path;
    }

    function search(q) {
        return list
            .filter(p => p.toLowerCase().includes(q))
            .sort((a, b) => basename(b).toLowerCase().startsWith(q) - basename(a).toLowerCase().startsWith(q));
    }

    Process {
        id: reader
        command: ["sh", "-c", `zoxide query -l | while IFS= read -r d; do
            for f in "$d"/.git "$d"/package.json "$d"/Cargo.toml "$d"/go.mod "$d"/pyproject.toml "$d"/*.sln "$d"/*.csproj; do
                if [ -e "$f" ]; then echo "$d"; break; fi
            done
        done`]
        stdout: StdioCollector {
            onStreamFinished: root.list = text.split("\n").filter(p => p && p !== root.home)
        }
    }
}
