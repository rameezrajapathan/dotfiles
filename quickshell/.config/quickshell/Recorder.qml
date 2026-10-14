pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screen recording state for the bar: whether wf-recorder (hypr/scripts/record.sh) is running and
// for how long. record.sh writes the output path to $XDG_RUNTIME_DIR/recording-path when it
// starts, so that file's age is the elapsed time.
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/record.sh"
    property bool active: false
    property real startedAt: 0
    readonly property int elapsed: active && startedAt > 0 ? Math.max(0, Math.floor(clock.date.getTime() / 1000 - startedAt)) : 0
    readonly property string elapsedText: {
        const s = elapsed;
        const hms = [Math.floor(s / 3600), Math.floor(s / 60) % 60, s % 60].map(n => String(n).padStart(2, "0"));
        return s >= 3600 ? hms.join(":") : hms.slice(1).join(":");
    }

    // "region" or "full"; also stops a running recording
    function record(what) {
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; exec " + script + " " + what]);
    }

    function stop() {
        Quickshell.execDetached([script]);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        enabled: root.active
    }

    Process {
        id: check
        command: ["sh", "-c", "pgrep -x wf-recorder >/dev/null && stat -c %Y \"$XDG_RUNTIME_DIR/recording-path\""]
        stdout: StdioCollector {
            onStreamFinished: root.startedAt = Number(text.trim()) || 0
        }
        onExited: code => root.active = code === 0
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: check.running = true
    }
}
