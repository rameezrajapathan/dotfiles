import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.services

Scope {
    id: root

    readonly property int duration: Theme.ms(180)
    readonly property int steps: 14
    readonly property int margin: 20

    property real workspaceChangedAt: 0
    property var openedAt: ({})
    property string pending: ""
    property string lastActive: ""

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const now = Date.now();
            switch (event.name) {
            case "workspacev2":
            case "activespecialv2":
                root.workspaceChangedAt = now;
                break;
            case "openwindow":
                if (Object.keys(root.openedAt).length > 50)
                    root.openedAt = {};
                root.openedAt[event.data.split(",")[0]] = now;
                break;
            case "activewindowv2": {
                const address = event.data.replace(/^0x/, "");
                if (address === root.lastActive)
                    return;
                root.lastActive = address;
                if (!address || now - root.workspaceChangedAt < 300 || now - (root.openedAt[address] ?? 0) < 1000)
                    return;
                root.pending = address;
                probe.running = false;
                probe.running = true;
                break;
            }
            }
        }
    }

    Process {
        id: probe
        command: ["sh", "-c", "a=$(hyprctl -j cursorpos); w=$(hyprctl -j activewindow); sleep 0.04; "
            + "printf '[%s,%s,%s]' \"$w\" \"$a\" \"$(hyprctl -j cursorpos)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let win, before, pos;
                try {
                    [win, before, pos] = JSON.parse(text);
                } catch (e) {
                    return;
                }
                if (!win?.address || win.address.replace(/^0x/, "") !== root.pending)
                    return;
                const [x, y] = win.at;
                const [w, h] = win.size;
                const m = root.margin;
                const near = pos.x >= x - m && pos.x < x + w + m && pos.y >= y - m && pos.y < y + h + m;
                const moving = pos.x !== before.x || pos.y !== before.y;
                if (near || moving)
                    return;
                root.glide(pos.x, pos.y, x + w / 2, y + h / 2);
            }
        }
    }

    function glide(fromX, fromY, toX, toY) {
        const points = [];
        for (let i = 1; i <= steps; i++) {
            const t = 1 - Math.pow(1 - i / steps, 3);
            points.push(Math.round(fromX + (toX - fromX) * t) + "," + Math.round(fromY + (toY - fromY) * t));
        }
        mover.running = false;
        mover.command = ["sh", "-c", `for p; do
            hyprctl dispatch "hl.dsp.cursor.move({ x = \${p%,*}, y = \${p#*,} })" >/dev/null
            sleep ${(Math.max(0, duration / steps - 4) / 1000).toFixed(3)}
        done`, "glide"].concat(points);
        mover.running = true;
    }

    Process {
        id: mover
    }
}
