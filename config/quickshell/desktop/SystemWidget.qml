import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

DesktopWidgetContent {
    id: root

    SysStatsWatch {
        active: root.live && root.visible
    }

    readonly property var stats: [
        { label: "CPU", value: SysStats.cpu, detail: Math.round(SysStats.cpu * 100) + "%" },
        { label: "Memory", value: SysStats.mem, detail: SysStats.gib(SysStats.memUsed) + " / " + SysStats.gib(SysStats.memTotal) + " GB" },
        { label: "Disk", value: SysStats.disk, detail: SysStats.gib(SysStats.diskUsed) + " / " + SysStats.gib(SysStats.diskTotal) + " GB" }
    ].concat(StatusInfo.battery.isLaptopBattery ? [{
        label: "Battery", value: StatusInfo.batteryPercent / 100, battery: true, detail: Math.round(StatusInfo.batteryPercent) + "%"
    }] : [])

    function tint(s, i) {
        const v = Math.max(0, Math.min(1, s.value));
        return s.battery ? (v <= 0.2 ? Theme.red : Theme.green) : v > 0.85 ? Theme.red : Theme.accents[i % 3];
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Desktop.showing = false;
            Panels.toggle("controlcenter", "system");
        }
    }

    GridLayout {
        anchors { fill: parent; margins: root.sizeClass === "large" ? 22 : 16 }
        columns: root.sizeClass === "small" ? 2 : root.sizeClass === "medium" ? root.stats.length : 1
        rowSpacing: root.sizeClass === "large" ? 14 : 6
        columnSpacing: 8

        Repeater {
            model: root.stats

            GridLayout {
                id: gauge
                required property var modelData
                required property int index
                readonly property bool wide: root.sizeClass === "large"
                Layout.fillWidth: true
                Layout.fillHeight: !wide
                Layout.preferredWidth: 1
                columns: wide ? 2 : 1
                columnSpacing: 16
                rowSpacing: 4

                RingGauge {
                    Layout.alignment: Qt.AlignCenter
                    size: gauge.wide ? 64 : root.sizeClass === "small" ? Math.min(gauge.width, 66) : Math.min(gauge.width, 84)
                    value: gauge.modelData.value
                    tint: root.tint(gauge.modelData, gauge.index)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: gauge.wide ? Text.AlignLeft : Text.AlignHCenter
                        text: gauge.modelData.label.toUpperCase()
                        color: Theme.overlay
                        font.pixelSize: Theme.fontSize - 3
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                    }
                    Label {
                        visible: gauge.wide || root.sizeClass === "medium"
                        Layout.fillWidth: true
                        horizontalAlignment: gauge.wide ? Text.AlignLeft : Text.AlignHCenter
                        text: gauge.modelData.detail
                        color: gauge.wide ? Theme.text : Theme.subtext
                        font.pixelSize: gauge.wide ? Theme.fontSize + 2 : Theme.fontSize - 2
                        font.weight: gauge.wide ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
