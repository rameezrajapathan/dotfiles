import Quickshell
import QtQuick

// Opens the wallpaper picker.
Label {
    font.pixelSize: Theme.fontSize + 3
    text: "󰸉"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "toggle"])
    }
}
