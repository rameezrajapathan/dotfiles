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

    property var backup: null

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
    property var snapshots: null

    Process {
        id: snapshotReader
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/snapshots.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.snapshots = JSON.parse(text);
                } catch (e) {
                    root.snapshots = null;
                }
            }
        }
    }
    SysStatsWatch {
        active: root.shown
    }

    onShownChanged: if (shown) snapshotReader.running = true

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
                    tip: "Open system monitor"
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
                columns: SysStats.gpuState !== "" ? 4 : 3
                columnSpacing: 8

                Meter {
                    label: "CPU"
                    slot: 0
                    value: SysStats.cpu
                    detail: SysStats.cpuTemp ? SysStats.cpuTemp + "°C" : ""
                }
                Meter {
                    label: "Memory"
                    slot: 1
                    value: SysStats.mem
                    detail: SysStats.memTotal > 0 ? SysStats.gib(SysStats.memUsed) + " / " + SysStats.gib(SysStats.memTotal) + " GiB" : ""
                }
                Meter {
                    label: "GPU"
                    slot: 0
                    visible: SysStats.gpuState !== ""
                    value: SysStats.gpu?.util ?? 0
                    dimmed: !SysStats.gpu
                    detail: SysStats.gpu ? SysStats.gpu.temp + "°C · " + Math.round(SysStats.gpu.watts) + " W" : "sleeping"
                }
                Meter {
                    label: "Disk /"
                    slot: 2
                    value: SysStats.disk
                    detail: SysStats.diskTotal > 0 ? SysStats.gib(SysStats.diskUsed) + " / " + SysStats.gib(SysStats.diskTotal) + " GiB" : ""
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
                        : root.backup.ok ? "Backup " + TimeDate.ago(root.backup.time * 1000) + "  ·  " + root.backup.snapshots + " snapshots"
                        : "Backup failed: " + root.backup.message
                    color: root.backup && !root.backup.ok ? Theme.red : Theme.text
                    elide: Text.ElideRight
                }
                Pill {
                    icon: "backup"
                    tip: "Back up now"
                    onClicked: Quickshell.execDetached(["systemctl", "--user", "start", "--no-block", "pikadots-backup.service"])
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.snapshots?.count != null
                spacing: 8

                Icon {
                    name: "history"
                    size: 18
                    color: Date.now() / 1000 - (root.snapshots?.latest ?? 0) > 604800 ? Theme.yellow : Theme.accent
                }
                Label {
                    Layout.fillWidth: true
                    text: !root.snapshots?.count ? "No system snapshots"
                        : "Snapshot " + TimeDate.ago(root.snapshots.latest * 1000) + "  ·  " + root.snapshots.count
                            + (root.snapshots.source === "grub-btrfs" ? " in the boot menu" : " snapshots")
                    color: Theme.text
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: (SysStats.fans?.length ?? 0) > 0
                spacing: 14

                Icon {
                    name: "mode_fan"
                    size: 18
                    color: Theme.subtext
                }
                Repeater {
                    model: SysStats.fans ?? []

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
                model: SysStats.procs ?? []

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
