pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// pikadots and system updates (hypr/scripts/updates.sh): checked every
// Settings.updates.checkHours, with a notification when something new turns up. Updating runs in
// the default terminal, since it may ask for the sudo password. `qs ipc call updates check`.
Singleton {
    id: root

    property var pikadots: null
    property var system: null
    property real checked: 0
    property bool checking: false

    readonly property int behind: pikadots?.behind ?? 0
    readonly property int systemCount: system ? system.pacman.length + system.aur.length + system.flatpak.length : 0
    readonly property int count: behind + systemCount

    // Counts already announced, so a notification only comes for new updates
    property int notifiedBehind: 0
    property int notifiedSystem: 0

    function check() {
        if (checking)
            return;
        checking = true;
        proc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/updates.sh"].concat(Settings.updates.system ? [] : ["repo"]);
        proc.running = true;
    }

    // Checks unless the last check is recent (the Updates page opening)
    function checkIfOld() {
        if (Date.now() / 1000 - checked > 600)
            check();
    }

    function updatePikadots() {
        Apps.terminal(["sh", "-c", "pikadots update; echo; read -rp 'Done. Press Enter to close… ' _"]);
    }

    function updateSystem() {
        const helper = system?.helper || "";
        const steps = [helper ? helper + " -Syu" : "sudo pacman -Syu"];
        if ((system?.flatpak.length ?? 0) > 0)
            steps.push("flatpak update");
        Apps.terminal(["sh", "-c", steps.join(" && ") + "; echo; read -rp 'Done. Press Enter to close… ' _"]);
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

    // First check a minute after login, then every few hours
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
        onExited: root.checking = false
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
