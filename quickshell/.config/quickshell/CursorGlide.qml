import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Glides the mouse pointer to a window focused from the keyboard (movefocus, Alt + Tab, ...)
// instead of Hyprland's instant warp, which settings.lua turns off (cursor.no_warps).
// Skipped when the focus came from the mouse: the pointer is inside the window or within `margin` of
// it (Hyprland focuses on the border grab area, which resize_on_border extends ~15 px past the
// edge), or it's still moving. Also skipped for newly opened windows and right after a workspace
// switch (Hyprland doesn't warp there either).
Scope {
    id: root

    readonly property int duration: Theme.ms(180)
    // Each hyprctl call takes about 4 ms, taken off the sleep between steps
    readonly property int steps: 14
    // Border grab area (15) + border (2) + a little
    readonly property int margin: 20

    property real workspaceChangedAt: 0
    property var openedAt: ({})
    property string pending: ""

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

    // Where the window is, and the pointer twice 40 ms apart to tell whether it's moving
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
            const t = 1 - Math.pow(1 - i / steps, 3);  // ease out cubic
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
