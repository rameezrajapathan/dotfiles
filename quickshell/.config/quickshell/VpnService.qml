pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// NetworkManager VPN connections, polled with nmcli.
Singleton {
    id: root

    property var connections: [] // [{ name, active }]
    readonly property bool anyActive: connections.some(c => c.active)

    function refresh() {
        poll.running = true;
    }

    function toggle(name) {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/vpn.sh", name]);
        refreshSoon.restart();
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

    Timer {
        id: refreshSoon
        interval: 1500
        onTriggered: poll.running = true
    }
}
