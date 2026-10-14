import QtQuick

// Coffee cup while keep awake is on; click to turn it off.
Icon {
    visible: Toggles.keepAwake
    name: "coffee"
    filled: true
    color: Theme.accent

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Toggles.keepAwake = false
    }
}
