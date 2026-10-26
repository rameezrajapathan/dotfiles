import QtQuick
import qs.services

Rectangle {
    id: root
    property string text
    property string keys: ""

    implicitWidth: row.implicitWidth + 20
    implicitHeight: row.implicitHeight + 10
    width: implicitWidth
    height: implicitHeight
    radius: Theme.round(height / 2, width, height)
    color: Qt.alpha(Theme.mix(Theme.base, Theme.surface, 0.35), 0.96)
    border.width: 1
    border.color: Qt.alpha(Theme.accent, 0.35)
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.ms(120) } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Label {
            text: root.text
            font.pixelSize: Theme.fontSize - 1
        }
        Label {
            visible: root.keys !== ""
            text: root.keys
            color: Theme.accent
            font.pixelSize: Theme.fontSize - 2
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
