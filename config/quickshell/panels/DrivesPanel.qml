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

    onShownChanged: if (shown) Drives.refresh()

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
        spacing: 4

        Label {
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            text: "Drives"
            font.bold: true
        }

        Label {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            visible: Drives.volumes.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: "No USB drives or SD cards"
            color: Theme.subtext
        }

        Repeater {
            model: Drives.volumes

            ColumnLayout {
                id: drive
                required property var modelData
                readonly property bool mounted: modelData.mountpoint !== ""
                Layout.fillWidth: true
                spacing: 2

                PanelRow {
                    Layout.fillWidth: true
                    icon: drive.modelData.icon
                    title: drive.modelData.name
                    highlighted: drive.mounted
                    detail: drive.modelData.locked ? "locked"
                        : drive.mounted ? Drives.formatSize(drive.modelData.size - drive.modelData.used) + " free"
                        : Drives.formatSize(drive.modelData.size)
                    onClicked: {
                        root.closeRequested();
                        Drives.open(drive.modelData);
                    }

                    Pill {
                        icon: "eject"
                        onClicked: Drives.eject(drive.modelData)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 36
                    Layout.rightMargin: 8
                    Layout.bottomMargin: 4
                    visible: drive.mounted && drive.modelData.size > 0
                    implicitHeight: 4
                    radius: 2
                    color: Theme.surface

                    Rectangle {
                        width: parent.width * Math.min(1, drive.modelData.used / Math.max(1, drive.modelData.size))
                        height: parent.height
                        radius: 2
                        color: drive.modelData.used / Math.max(1, drive.modelData.size) > 0.9 ? Theme.red : Theme.accent
                    }
                }
            }
        }
    }
}
