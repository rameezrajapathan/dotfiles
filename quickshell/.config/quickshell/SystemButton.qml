import QtQuick

// Opens SystemPanel.
Icon {
    id: root
    signal clicked()

    name: "monitoring"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
