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
        { label: "CPU", value: SysStats.cpu, text: Math.round(SysStats.cpu * 100) + "%" },
        { label: "Memory", value: SysStats.mem, text: SysStats.gib(SysStats.memUsed) + " GB" },
        { label: "Disk", value: SysStats.disk, text: Math.round(SysStats.disk * 100) + "%" }
    ].concat(StatusInfo.battery.isLaptopBattery ? [{
        label: "Battery", value: StatusInfo.batteryPercent / 100, text: StatusInfo.batteryPercent + "%", good: true
    }] : [])

    GridLayout {
        id: grid
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        columns: root.stats.length
        columnSpacing: 14

        Repeater {
            model: root.stats

            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: 6

                Label {
                    text: modelData.label.toUpperCase()
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 3
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                }
                Label {
                    text: modelData.text
                    font.pixelSize: Theme.fontSize + 3
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Qt.alpha(Theme.surface, 0.9)
                    Rectangle {
                        width: parent.width * Math.min(1, modelData.value)
                        height: parent.height
                        radius: 3
                        color: modelData.good ? Theme.green : modelData.value > 0.85 ? Theme.red : Theme.accent
                        Behavior on width { NumberAnimation { duration: Theme.ms(300) } }
                    }
                }
            }
        }
    }
}
