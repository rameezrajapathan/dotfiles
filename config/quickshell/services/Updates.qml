pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var pikadots: null
    property var system: null
    property real checked: 0
    property bool checking: false
    property bool recheck: false
    readonly property string afterRun: "; qs ipc call updates check >/dev/null 2>&1; echo; read -rp 'Done. Press Enter to close… ' _"

    readonly property int behind: pikadots?.behind ?? 0
    readonly property int systemCount: system ? system.pacman.length + system.aur.length + system.flatpak.length : 0
    readonly property int count: behind + systemCount

    property int notifiedBehind: 0
    property int notifiedSystem: 0

    function check() {
        if (checking) {
            recheck = true;
            return;
        }
        checking = true;
        proc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/updates.sh"].concat(Settings.updates.system ? [] : ["repo"]);
        proc.running = true;
    }

    function checkIfOld() {
        if (Date.now() / 1000 - checked > 600)
            check();
    }

    function updatePikadots() {
        Apps.terminal(["sh", "-c", "\"$HOME/.local/bin/pikadots\" update" + afterRun]);
    }

    function repairPikadots() {
        Apps.terminal(["sh", "-c", "\"$HOME/.local/bin/pikadots\" repair" + afterRun]);
    }

    function updateSystem() {
        const helper = system?.helper || "";
        const steps = [helper ? helper + " -Syu" : "sudo pacman -Syu"];
        if ((system?.flatpak.length ?? 0) > 0)
            steps.push("flatpak update");
        Apps.terminal(["sh", "-c", steps.join(" && ") + afterRun]);
    }

    function ago(seconds) {
        const s = Date.now() / 1000 - seconds;
        return s < 90 ? "just now" : s < 3600 ? Math.round(s / 60) + " min ago"
            : s < 86400 ? Math.round(s / 3600) + " h ago" : Math.round(s / 86400) + " days ago";
    }

    IpcHandler {
        target: "updates"
        function check(): void {
            root.check();
        }
    }

    Timer {
        interval: 60000
        running: Settings.updates.checkHours > 0
        onTriggered: root.check()
    }
    Timer {
        interval: Math.max(1, Settings.updates.checkHours) * 3600000
        running: Settings.updates.checkHours > 0
        repeat: true
        onTriggered: root.check()
    }

    FileView {
        path: "/var/log/pacman.log"
        preload: false
        watchChanges: true
        onFileChanged: settleTimer.restart()
    }
    Timer {
        id: settleTimer
        interval: 8000
        onTriggered: root.check()
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                root.checking = false;
                let r;
                try {
                    r = JSON.parse(text);
                } catch (e) {
                    return;
                }
                root.pikadots = r.pikadots;
                root.system = r.system;
                root.checked = r.checked;
                root.announce();
            }
        }
        onExited: {
            root.checking = false;
            if (root.recheck) {
                root.recheck = false;
                root.check();
            }
        }
    }

    function announce() {
        const newPikadots = behind > notifiedBehind;
        const newSystem = systemCount > notifiedSystem + 9 || (notifiedSystem === 0 && systemCount > 0);
        if (Settings.updates.notify && (newPikadots || newSystem)) {
            const parts = [];
            if (behind > 0)
                parts.push("pikadots: " + behind + " new change" + (behind === 1 ? "" : "s"));
            if (systemCount > 0)
                parts.push(systemCount + " package update" + (systemCount === 1 ? "" : "s"));
            Quickshell.execDetached(["notify-send", "-a", "Updates", "-i", "system-software-update",
                "Updates available", parts.join("\n") + "\nSettings › Updates"]);
        }
        notifiedBehind = behind;
        notifiedSystem = systemCount;
    }
}
