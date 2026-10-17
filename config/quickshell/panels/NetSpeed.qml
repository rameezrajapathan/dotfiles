import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    property bool active: false

    readonly property int samples: 60
    property real down: 0
    property real up: 0
    property var downHistory: []
    property var upHistory: []
    property var last: null

    implicitHeight: column.implicitHeight + 24
    radius: Theme.round(12, width, height)
    color: Qt.alpha(Theme.surface, 0.5)

    onActiveChanged: {
        last = null;
        if (active)
            stats.reload();
    }

    function format(bytes) {
        const units = ["B/s", "KB/s", "MB/s", "GB/s"];
        let i = 0;
        while (bytes >= 1000 && i < units.length - 1) {
            bytes /= 1000;
            i++;
        }
        return (i === 0 ? Math.round(bytes) : bytes.toFixed(bytes < 10 ? 1 : 0)) + " " + units[i];
    }

    function sample(text) {
        let rx = 0, tx = 0;
        for (const line of text.split("\n").slice(2)) {
            const [name, rest] = line.split(":");
            if (!rest || /^(lo|tun|tap|wg|ppp|docker|veth|br-|virbr|vnet|tailscale|zt)/.test(name.trim()))
                continue;
            const f = rest.trim().split(/\s+/);
            rx += Number(f[0]);
            tx += Number(f[8]);
        }
        const now = Date.now();
        if (last && now > last.time) {
            const secs = (now - last.time) / 1000;
            down = Math.max(0, rx - last.rx) / secs;
            up = Math.max(0, tx - last.tx) / secs;
            downHistory = downHistory.concat([down]).slice(-samples);
            upHistory = upHistory.concat([up]).slice(-samples);
            graph.requestPaint();
        }
        last = { rx: rx, tx: tx, time: now };
    }

    FileView {
        id: stats
        path: "/proc/net/dev"
        onLoaded: root.sample(text())
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: stats.reload()
    }

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(12, 12, parent.width, parent.height) }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Speed {
                icon: "arrow_downward"
                label: "Download"
                value: root.format(root.down)
                color: Theme.accent
            }
            Speed {
                icon: "arrow_upward"
                label: "Upload"
                value: root.format(root.up)
                color: Theme.green
            }
            Item { Layout.fillWidth: true }
            Label {
                Layout.alignment: Qt.AlignTop
                text: "peak " + root.format(Math.max(0, ...root.downHistory, ...root.upHistory))
                color: Theme.overlay
                font.pixelSize: Theme.fontSize - 3
            }
        }

        Canvas {
            id: graph
            Layout.fillWidth: true
            implicitHeight: 54

            onWidthChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const peak = Math.max(1024, ...root.downHistory, ...root.upHistory);
                const step = width / (root.samples - 1);
                const y = v => height - 2 - v / peak * (height - 4);

                function trace(values) {
                    const x0 = width - (values.length - 1) * step;
                    ctx.beginPath();
                    values.forEach((v, i) => i === 0 ? ctx.moveTo(x0, y(v)) : ctx.lineTo(x0 + i * step, y(v)));
                    return x0;
                }

                ctx.strokeStyle = Qt.alpha(Theme.overlay, 0.35);
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(0, height - 1.5);
                ctx.lineTo(width, height - 1.5);
                ctx.stroke();

                if (root.downHistory.length < 2)
                    return;

                const x0 = trace(root.downHistory);
                ctx.lineTo(width, height);
                ctx.lineTo(x0, height);
                ctx.closePath();
                ctx.fillStyle = Qt.alpha(Theme.accent, 0.18);
                ctx.fill();

                ctx.lineJoin = "round";
                ctx.lineWidth = 2;
                trace(root.downHistory);
                ctx.strokeStyle = Theme.accent;
                ctx.stroke();

                trace(root.upHistory);
                ctx.strokeStyle = Theme.green;
                ctx.stroke();
            }
        }

        GlassDivider {
            visible: SpeedTest.running || SpeedTest.hasResult
            Layout.fillWidth: true
            Layout.topMargin: 2
            implicitHeight: Glass.active ? 2 : 1
            vertical: false
            strength: 0.58
        }
        RowLayout {
            visible: SpeedTest.running || SpeedTest.hasResult
            Layout.fillWidth: true
            spacing: 16

            Icon {
                name: "speed"
                size: 18
                color: SpeedTest.running ? Theme.accent : Theme.subtext
            }
            Label {
                visible: SpeedTest.error !== ""
                Layout.fillWidth: true
                text: SpeedTest.error
                color: Theme.red
                elide: Text.ElideRight
            }
            SpeedTestResult {
                visible: SpeedTest.error === ""
                label: "Ping"
                value: SpeedTest.ping >= 0 ? Math.round(SpeedTest.ping) + " ms" : ""
                testing: SpeedTest.phase === "ping"
            }
            SpeedTestResult {
                visible: SpeedTest.error === ""
                label: "Download"
                value: SpeedTest.down >= 0 ? SpeedTest.down.toFixed(1) + " Mbit/s" : ""
                testing: SpeedTest.phase === "down"
            }
            SpeedTestResult {
                visible: SpeedTest.error === ""
                label: "Upload"
                value: SpeedTest.up >= 0 ? SpeedTest.up.toFixed(1) + " Mbit/s" : ""
                testing: SpeedTest.phase === "up"
            }
            Item { Layout.fillWidth: true }
            Label {
                Layout.alignment: Qt.AlignBottom
                text: SpeedTest.running ? "testing…"
                    : "at " + Qt.formatTime(SpeedTest.finishedAt, "h:mm AP")
                color: Theme.overlay
                font.pixelSize: Theme.fontSize - 3
            }
        }
    }

    component Speed: RowLayout {
        id: speed
        property string icon
        property string label
        property string value
        property color color
        spacing: 8

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: Theme.round(15, width, height)
            color: Qt.alpha(speed.color, 0.18)

            Icon {
                anchors.centerIn: parent
                name: speed.icon
                size: 18
                color: speed.color
            }
        }
        ColumnLayout {
            spacing: 0

            Label {
                text: speed.label
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 3
            }
            Label {
                Layout.minimumWidth: 72
                text: speed.value
                font.bold: true
            }
        }
    }
    GlassRim {}
}
