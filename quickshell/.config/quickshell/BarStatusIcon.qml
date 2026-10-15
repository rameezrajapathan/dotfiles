import QtQuick
import QtQuick.Layouts

// A status icon in the bar (key: network, bluetooth, audio, battery or notifications), from
// StatusInfo.qml. Click opens its control center tab. Scrolling the sound icon changes the volume,
// right click mutes it; right click on Bluetooth turns it on or off, on notifications toggles Do
// Not Disturb. Battery shows its percentage, notifications their count.
Item {
    id: root
    required property string key
    signal clicked()

    readonly property int count: key === "notifications" && !NotificationService.dnd ? NotificationService.list.length : 0

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Icon {
            name: StatusInfo.icon(root.key)
            color: root.key === "battery" && StatusInfo.batteryPercent <= 15 && !StatusInfo.charging ? Theme.red : Theme.text
            opacity: mouse.containsMouse ? 0.7 : 1
        }
        Label {
            visible: root.key === "battery"
            text: StatusInfo.batteryPercent + "%"
        }
        Rectangle {
            visible: root.count > 0
            implicitWidth: Math.max(16, badge.implicitWidth + 8)
            implicitHeight: 16
            radius: 8
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
