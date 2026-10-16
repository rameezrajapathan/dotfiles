import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.controlcenter
import qs.services
import qs.widgets

Item {
    id: root
    property bool shown: false
    signal closeRequested()

    implicitHeight: content.implicitHeight + 40

    property var info: ({})
    property var backup: null

    function ago(seconds) {
        const m = Math.floor((Date.now() / 1000 - seconds) / 60);
        return m < 1 ? "just now" : m < 60 ? m + " min ago" : m < 1440 ? Math.floor(m / 60) + " h ago" : Math.floor(m / 1440) + " d ago";
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/pikadots/backup.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.backup = JSON.parse(text());
            } catch (e) {
                root.backup = null;
            }
        }
    }
    property var lastCpu: null
    property real cpu: 0

    function gib(bytes) {
        return (bytes / 1073741824).toFixed(1);
    }

    function parse(text) {
        const next = { fans: [], procs: [] };
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
                next.mem = { total: Number(f[1]) * 1024, used: (Number(f[1]) - Number(f[2])) * 1024 };
                break;
            case "disk":
                next.disk = { used: Number(f[1]), total: Number(f[2]) };
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
        info = next;
    }

    onShownChanged: if (shown) reader.running = true

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
        running: root.shown
        onTriggered: reader.running = true
    }

    Item {
        anchors.fill: parent

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(20, 24) }
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: "System"
                    font.bold: true
                }
                Pill {
                    icon: "monitoring"
                    onClicked: {
                        root.closeRequested();
                        Apps.terminal(["btop"]);
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                columns: root.info.gpuState !== undefined ? 4 : 3
                columnSpacing: 8

                Meter {
                    label: "CPU"
                    slot: 0
                    value: root.cpu
                    detail: root.info.cpuTemp ? root.info.cpuTemp + "°C" : ""
                }
                Meter {
                    label: "Memory"
                    slot: 1
                    value: root.info.mem ? root.info.mem.used / root.info.mem.total : 0
                    detail: root.info.mem ? root.gib(root.info.mem.used) + " / " + root.gib(root.info.mem.total) + " GiB" : ""
                }
                Meter {
                    label: "GPU"
                    slot: 0
                    visible: root.info.gpuState !== undefined
                    value: root.info.gpu?.util ?? 0
                    dimmed: !root.info.gpu
                    detail: root.info.gpu ? root.info.gpu.temp + "°C · " + Math.round(root.info.gpu.watts) + " W" : "sleeping"
                }
                Meter {
                    label: "Disk /"
                    slot: 2
                    value: root.info.disk ? root.info.disk.used / root.info.disk.total : 0
                    detail: root.info.disk ? root.gib(root.info.disk.used) + " / " + root.gib(root.info.disk.total) + " GiB" : ""
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Icon {
                    name: !root.backup ? "cloud_off" : root.backup.ok ? "cloud_done" : "cloud_alert"
                    filled: true
                    size: 18
                    color: !root.backup ? Theme.overlay : root.backup.ok ? Theme.accent : Theme.red
                }
                Label {
                    Layout.fillWidth: true
                    text: !root.backup ? "No backup yet"
                        : root.backup.ok ? "Backup " + root.ago(root.backup.time) + "  ·  " + root.backup.snapshots + " snapshots"
                        : "Backup failed: " + root.backup.message
                    color: root.backup && !root.backup.ok ? Theme.red : Theme.text
                    elide: Text.ElideRight
                }
                Pill {
                    icon: "backup"
                    onClicked: Quickshell.execDetached(["systemctl", "--user", "start", "--no-block", "pikadots-backup.service"])
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: (root.info.fans?.length ?? 0) > 0
                spacing: 14

                Icon {
                    name: "mode_fan"
                    size: 18
                    color: Theme.subtext
                }
                Repeater {
                    model: root.info.fans ?? []

                    Label {
                        required property var modelData
                        text: modelData.name + " " + modelData.rpm + " rpm"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }

            Label {
                Layout.topMargin: 2
                text: "Top processes"
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 2
            }
            Repeater {
                model: root.info.procs ?? []

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        Layout.fillWidth: true
                        text: modelData.name
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.preferredWidth: 60
                        horizontalAlignment: Text.AlignRight
                        text: modelData.cpu.toFixed(1) + "%"
                        color: Theme.accent
                    }
                    Label {
                        Layout.preferredWidth: 60
                        horizontalAlignment: Text.AlignRight
                        text: modelData.mem.toFixed(1) + "% mem"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }
        }
    }

    component Meter: ColumnLayout {
        id: meter
        property string label
        property string detail
        property real value: 0
        property bool dimmed: false
        property int slot: 0
        readonly property bool hot: value > 0.85

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        spacing: 6

        RingGauge {
            Layout.alignment: Qt.AlignHCenter
            size: Math.max(48, Math.min(72, meter.width))
            value: meter.value
            dimmed: meter.dimmed
            tint: meter.hot ? Theme.red : Theme.accents[meter.slot]
            tintEnd: Theme.multiColor && !meter.hot ? Theme.accents[(meter.slot + 1) % 3] : Theme.shade(tint)
        }
        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: meter.label.toUpperCase()
            color: Theme.overlay
            font.pixelSize: Theme.fontSize - 3
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
            elide: Text.ElideRight
        }
        Label {
            Layout.fillWidth: true
            Layout.topMargin: -4
            visible: meter.detail !== ""
            horizontalAlignment: Text.AlignHCenter
            text: meter.detail
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 3
            wrapMode: Text.WordWrap
        }
    }
}
