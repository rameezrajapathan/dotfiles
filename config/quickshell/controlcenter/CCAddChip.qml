import QtQuick
import qs.services
import qs.widgets

Rectangle {
    id: chip
    property string icon
    property string text
    signal clicked()

    implicitWidth: chipRow.implicitWidth + 22
    implicitHeight: 32
    radius: height / 2
    color: chipMouse.containsMouse ? Qt.alpha(Theme.accent, 0.22) : Qt.alpha(Theme.base, 0.6)
    border.width: 1
    border.color: Qt.alpha(Theme.overlay, 0.3)

    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: 6
        Icon { name: "add"; size: 15; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        Icon { name: chip.icon; size: 16; anchors.verticalCenter: parent.verticalCenter }
        Label { text: chip.text; font.pixelSize: Theme.fontSize - 1; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
