import QtQuick

// Opens QuickSettingsPanel.
Icon {
    id: root
    signal clicked()

    name: "tune"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
