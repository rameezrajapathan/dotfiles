pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real value: -1
    readonly property bool available: value >= 0

    function refresh() {
        reader.running = true;
    }

    function set(v) {
        value = Math.max(0.01, Math.min(1, v));
        writeTimer.restart();
    }

    Timer {
        id: writeTimer
        interval: 50
        onTriggered: Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.round(root.value * 100) + "%"])
    }

    Process {
        id: reader
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")[0]?.split(",") ?? [];
                const max = Number(f[4]);
                root.value = f.length >= 5 && max > 0 ? Number(f[2]) / max : -1;
            }
        }
    }
}
