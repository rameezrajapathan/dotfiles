pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screen backlight through brightnessctl, for the control center's slider. Read when asked
// (refresh), so keys that change it elsewhere show up next time the control center opens.
Singleton {
    id: root

    // 0..1; -1 until read, or when there is no backlight (desktops)
    property real value: -1
    readonly property bool available: value >= 0

    function refresh() {
        reader.running = true;
    }

    // Applied at most every 50 ms while dragging
    function set(v) {
        value = Math.max(0.01, Math.min(1, v));
        writeTimer.restart();
    }

    Timer {
        id: writeTimer
        interval: 50
        onTriggered: Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.round(root.value * 100) + "%"])
    }

    // brightnessctl -m prints "device,class,current,percent%,max"
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
