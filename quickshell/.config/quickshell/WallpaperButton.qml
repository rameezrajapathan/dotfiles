import Quickshell
import QtQuick

// Opens the wallpaper picker.
Icon {
    name: "wallpaper"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "toggle"])
    }
}
