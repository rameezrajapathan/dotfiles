import QtQuick
import qs.services

Rectangle {
    implicitWidth: 18
    implicitHeight: 18
    radius: Theme.round(width / 2, width, height)
    color: Theme.accent
    gradient: Theme.accentFill(true)
    Icon {
        anchors.centerIn: parent
        name: "check"
        size: 14
        color: Theme.accentText
    }
}
