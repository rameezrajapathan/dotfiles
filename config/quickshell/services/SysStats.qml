pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int watchers: 0
    property real cpu: 0
    property real memUsed: 0
    property real memTotal: 0
    property real diskUsed: 0
    property real diskTotal: 0
    property var lastCpu: null

    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0
    readonly property real disk: diskTotal > 0 ? diskUsed / diskTotal : 0

    function watch(on) {
        watchers = Math.max(0, watchers + (on ? 1 : -1));
        if (on && watchers === 1) {
            reader.running = true;
            secondRead.restart();
        }
    }

    Timer {
        id: secondRead
        interval: 500
        onTriggered: reader.running = true
    }

    function gib(bytes) {
        return (bytes / 1073741824).toFixed(1);
    }

    function parse(text) {
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            if (f[0] === "cpu") {
                const busy = Number(f[1]), idle = Number(f[2]);
                if (lastCpu) {
                    const db = busy - lastCpu.busy, di = idle - lastCpu.idle;
                    cpu = db + di > 0 ? db / (db + di) : 0;
                }
                lastCpu = { busy: busy, idle: idle };
            } else if (f[0] === "mem") {
                memTotal = Number(f[1]) * 1024;
                memUsed = (Number(f[1]) - Number(f[2])) * 1024;
            } else if (f[0] === "disk") {
                diskUsed = Number(f[1]);
                diskTotal = Number(f[2]);
            }
        }
    }

    Process {
        id: reader
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/sysinfo.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.watchers > 0
        onTriggered: reader.running = true
    }
}
