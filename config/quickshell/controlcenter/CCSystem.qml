import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

CCCard {
    id: root
    property var cc

    clickable: true
    onClicked: cc.openDetail("system")
    implicitHeight: grid.implicitHeight + 28

    readonly property bool watching: cc?.open ?? false
    onWatchingChanged: SysStats.watch(watching)
    Component.onDestruction: if (watching) SysStats.watch(false)

    readonly property var stats: [
        { label: "CPU", value: SysStats.cpu },
        { label: "Memory", value: SysStats.mem, detail: SysStats.gib(SysStats.memUsed) + " GB" },
        { label: "Disk", value: SysStats.disk }
    ].concat(StatusInfo.battery.isLaptopBattery ? [{
        label: "Battery", value: StatusInfo.batteryPercent / 100, battery: true
    }] : [])

    GridLayout {
        id: grid
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(14, 22) }
        columns: root.stats.length
        columnSpacing: 10

        Repeater {
            model: root.stats

            ColumnLayout {
                id: gauge
                required property var modelData
                required property int index
                readonly property real value: Math.max(0, Math.min(1, modelData.value))
                readonly property color tint: modelData.battery ? (value <= 0.2 ? Theme.red : Theme.green)
                    : value > 0.85 ? Theme.red : Theme.accents[index % 3]

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: 6

                RingGauge {
                    Layout.alignment: Qt.AlignHCenter
                    size: Math.max(44, Math.min(68, gauge.width))
                    value: gauge.value
                    tint: gauge.tint
                    tintEnd: Theme.multiColor && !gauge.modelData.battery && gauge.value <= 0.85 ? Theme.accents[(gauge.index + 1) % 3] : Theme.shade(gauge.tint)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: gauge.modelData.label.toUpperCase()
                        color: Theme.overlay
                        font.pixelSize: Theme.fontSize - 3
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: gauge.modelData.detail ?? ""
                        visible: root.stats.some(s => s.detail)
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 3
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
