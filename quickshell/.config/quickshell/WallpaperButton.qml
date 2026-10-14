import Quickshell
import QtQuick

// Opens the wallpaper picker (which also recolors everything).
Icon {
    name: "palette"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "toggle"])
    }
}
