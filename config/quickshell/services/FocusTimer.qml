pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property var lengths: ({ focus: 25, short: 5, long: 15 })
    property string mode: "focus"
    property int left: lengths.focus * 60
    property bool running: false
    property int rounds: 0
    readonly property int total: lengths[mode] * 60
    readonly property real fraction: total > 0 ? left / total : 0

    function toggle() {
        running = !running;
    }

    function reset() {
        running = false;
        left = total;
    }

    function skip() {
        if (mode === "focus") {
            rounds++;
            mode = rounds % 4 === 0 ? "long" : "short";
        } else {
            mode = "focus";
        }
        left = total;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.left > 1) {
                root.left--;
                return;
            }
            const was = root.mode;
            root.skip();
            Quickshell.execDetached(["notify-send", "-a", "Focus timer", "-i", "alarm",
                was === "focus" ? "Time for a break" : "Back to focus",
                was === "focus" ? root.lengths[root.mode] + " minutes. Stand up, stretch, look away from the screen." : "25 minutes of focus start now."]);
        }
    }
}
