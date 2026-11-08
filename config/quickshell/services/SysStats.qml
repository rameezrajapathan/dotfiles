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
    property real cpuTemp: 0
    property var fans: []
    property string gpuState: ""
    property var gpu: null
    property var procs: []
    property var lastCpu: null

    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0
    readonly property real disk: diskTotal > 0 ? diskUsed / diskTotal : 0

    property var osRelease: ({})
    property real uptimeSeconds: 0
    property var facts: ({})
    property bool factsLoaded: false

    function watch(on) {
        watchers = Math.max(0, watchers + (on ? 1 : -1));
        if (on && watchers === 1) {
            reader.running = true;
            secondRead.restart();
        }
    }

    function gib(bytes) {
        return (bytes / 1073741824).toFixed(1);
    }

    function refreshUptime() {
        uptimeFile.reload();
    }

    function uptimeText(compact) {
        const mins = Math.floor(uptimeSeconds / 60);
        const d = Math.floor(mins / 1440), h = Math.floor(mins / 60) % 24, m = mins % 60;
        if (compact)
            return (d > 0 ? d + "d " : "") + (d > 0 || h > 0 ? h + "h " : "") + m + "m";
        return (d > 0 ? d + " d " : "") + (d > 0 || h > 0 ? h + " h " : "") + m + " min";
    }

    function loadFacts() {
        if (!factsLoaded && !factsReader.running)
            factsReader.running = true;
    }

    function parse(text) {
        const next = { cpuTemp: 0, fans: [], gpuState: "", gpu: null, procs: [] };
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            switch (f[0]) {
            case "cpu": {
                const busy = Number(f[1]), idle = Number(f[2]);
                if (lastCpu) {
                    const db = busy - lastCpu.busy, di = idle - lastCpu.idle;
                    cpu = db + di > 0 ? db / (db + di) : 0;
                }
                lastCpu = { busy: busy, idle: idle };
                break;
            }
            case "mem":
                memTotal = Number(f[1]) * 1024;
                memUsed = (Number(f[1]) - Number(f[2])) * 1024;
                break;
            case "disk":
                diskUsed = Number(f[1]);
                diskTotal = Number(f[2]);
                break;
            case "cputemp":
                next.cpuTemp = Number(f[1]);
                break;
            case "fan":
                next.fans.push({ name: f[1].replace("_fan", ""), rpm: Number(f[2]) });
                break;
            case "gpustate":
                next.gpuState = f[1];
                break;
            case "gpu":
                next.gpu = { util: Number(f[1]) / 100, memUsed: Number(f[2]), memTotal: Number(f[3]), temp: Number(f[4]), watts: Number(f[5]), name: f.slice(6).join(" ") };
                break;
            case "proc":
                next.procs.push({ cpu: Number(f[1]), mem: Number(f[2]), name: f.slice(3).join(" ") });
                break;
            }
        }
        cpuTemp = next.cpuTemp;
        fans = next.fans;
        gpuState = next.gpuState;
        gpu = next.gpu;
        procs = next.procs;
    }

    Timer {
        id: secondRead
        interval: 500
        onTriggered: reader.running = true
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

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const fields = {};
            for (const line of text().split("\n")) {
                const m = line.match(/^(\w+)=["']?(.*?)["']?$/);
                if (m)
                    fields[m[1]] = m[2];
            }
            root.osRelease = fields;
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = parseFloat(text().split(" ")[0]) || 0
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: uptimeFile.reload()
    }

    Process {
        id: factsReader
        command: ["sh", "-c", `
            . /etc/os-release 2>/dev/null
            printf 'os=%s\\n' "\${PRETTY_NAME:-Linux}"
            printf 'logo=%s\\n' "\${LOGO:-\${ID:-linux}}"
            printf 'kernel=%s\\n' "$(uname -r)"
            printf 'host=%s\\n' "$(cat /etc/hostname 2>/dev/null || uname -n)"
            if command -v pacman >/dev/null; then n=$(pacman -Qq | wc -l); printf 'packages=%s (pacman)\\n' "$n"
            elif command -v rpm >/dev/null; then n=$(rpm -qa | wc -l); printf 'packages=%s (rpm)\\n' "$n"
            elif command -v dpkg-query >/dev/null; then n=$(dpkg-query -f '.\\n' -W | wc -l); printf 'packages=%s (dpkg)\\n' "$n"; fi
            command -v flatpak >/dev/null && printf 'flatpaks=%s\\n' "$(flatpak list --app 2>/dev/null | wc -l)"
            printf 'shell=%s\\n' "$(basename "\${SHELL:-sh}")"
            printf 'wm=Hyprland %s\\n' "$(hyprctl version -j 2>/dev/null | sed -n 's/.*"tag": *"v\\{0,1\\}\\([^"]*\\)".*/\\1/p' | head -1)"
            printf 'cpu=%s\\n' "$(sed -n 's/^model name\\s*: *//p' /proc/cpuinfo | head -1 | sed 's/([^)]*)//g; s/ CPU//; s/ \\{2,\\}/ /g; s/ [0-9]*-Core Processor//')"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        o[line.slice(0, i)] = line.slice(i + 1).trim();
                }
                if (o.flatpaks && o.flatpaks !== "0")
                    o.packages = (o.packages ? o.packages + ", " : "") + o.flatpaks + " (flatpak)";
                root.facts = o;
                root.factsLoaded = true;
            }
        }
    }
}
