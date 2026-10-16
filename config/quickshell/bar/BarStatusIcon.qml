import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    required property string key
    signal clicked()

    readonly property int count: key === "notifications" && !NotificationService.dnd ? NotificationService.list.length : 0

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    GridLayout {
        id: row
        anchors.centerIn: parent
        flow: Theme.barVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rowSpacing: 2
        columnSpacing: 3

        Icon {
            name: StatusInfo.icon(root.key)
            color: root.key === "battery" && StatusInfo.batteryPercent <= 15 && !StatusInfo.charging ? Theme.red : Theme.text
            opacity: mouse.containsMouse ? 0.7 : 1
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            visible: root.key === "battery"
            Layout.alignment: Qt.AlignHCenter
            text: StatusInfo.batteryPercent + (Theme.barVertical ? "" : "%")
        }
        Rectangle {
            visible: root.count > 0
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.max(16, badge.implicitWidth + 8)
            implicitHeight: 16
            radius: Theme.round(8, width, height)
            color: Theme.accent
            Label {
                id: badge
                anchors.centerIn: parent
                text: root.count > 99 ? "99+" : root.count
                color: Theme.accentText
                font.pixelSize: Theme.fontSize - 3
                font.bold: true
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                root.clicked();
            else if (root.key === "audio" && StatusInfo.sink?.audio)
                StatusInfo.sink.audio.muted = !StatusInfo.sink.audio.muted;
            else if (root.key === "bluetooth" && StatusInfo.btAdapter)
                StatusInfo.btAdapter.enabled = !StatusInfo.btAdapter.enabled;
            else if (root.key === "notifications")
                NotificationService.dnd = !NotificationService.dnd;
        }
        onWheel: wheel => {
            if (root.key === "audio" && StatusInfo.sink?.audio)
                StatusInfo.sink.audio.volume = Math.max(0, Math.min(1, StatusInfo.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
        }
    }
}
