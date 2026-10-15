pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Internet speed test (hypr/scripts/speedtest.sh, Cloudflare via curl): ping, then download, then
// upload, each filled in as it finishes. The Network tab starts it and shows the results.
Singleton {
    id: root

    readonly property bool running: proc.running
    // "ping", "down", "up" while running; "" otherwise
    property string phase: ""
    property real ping: -1
    property real down: -1
    property real up: -1
    property string error: ""
    property date finishedAt
    readonly property bool hasResult: ping >= 0 || error !== ""

    function start() {
        if (running)
            return;
        ping = down = up = -1;
        error = "";
        phase = "ping";
        proc.running = true;
    }

    function cancel() {
        proc.running = false;
    }

    Process {
        id: proc
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/speedtest.sh"]
        stdout: SplitParser {
            onRead: line => {
                const [key, ...rest] = line.split(" ");
                const value = rest.join(" ");
                switch (key) {
                case "ping": root.ping = Number(value); root.phase = "down"; break;
                case "down": root.down = Number(value); root.phase = "up"; break;
                case "up": root.up = Number(value); break;
                case "error": root.error = value; break;
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0 && root.error === "" && root.up < 0)
                root.error = root.phase === "" ? "" : "Stopped";
            root.phase = "";
            root.finishedAt = new Date();
        }
    }
}
