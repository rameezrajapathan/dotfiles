import QtQuick

// Opens DisplayPanel. Filled while an external monitor is on.
Icon {
    id: root
    signal clicked()

    name: "monitor"
    filled: Displays.external
    color: Displays.external ? Theme.accent : Theme.text

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
