pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// NetworkManager VPN connections, polled with nmcli.
Singleton {
    id: root

    property var connections: [] // [{ name, active }]
    readonly property bool anyActive: connections.some(c => c.active)
    // Connections being switched, name -> wanted state; cleared once nmcli reports it.
    property var pending: ({})

    function refresh() {
        poll.running = true;
    }

    function toggle(name) {
        const conn = connections.find(c => c.name === name);
        pending = Object.assign({}, pending, { [name]: !(conn?.active ?? false) });
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/vpn.sh", name]);
        refreshSoon.restart();
        pendingTimeout.restart();
    }

    Process {
        id: poll
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.trim().split("\n")) {
                    // NAME may contain escaped colons, so read TYPE and ACTIVE from the end.
                    const fields = line.split(":");
                    const active = fields.pop() === "yes";
                    const type = fields.pop();
                    if (type === "vpn" || type === "wireguard")
                        result.push({ name: fields.join(":").replace(/\\/g, ""), active });
                }
                root.connections = result;
                const still = {};
                for (const c of result)
                    if (c.name in root.pending && root.pending[c.name] !== c.active)
                        still[c.name] = root.pending[c.name];
                root.pending = still;
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    // Give up on "connecting…" if the state never changes (e.g. the password prompt was cancelled).
    Timer {
        id: pendingTimeout
        interval: 30000
        onTriggered: root.pending = {}
    }

    Timer {
        id: refreshSoon
        interval: 1500
        onTriggered: poll.running = true
    }
}
