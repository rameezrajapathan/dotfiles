import Quickshell
import QtQuick

// Power icon at the end of the bar; opens PowerMenu.
Icon {
    name: "power_settings_new"
    color: mouse.containsMouse ? Theme.red : Theme.text

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "power", "toggle"])
    }
}
