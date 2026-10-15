import QtQuick

// Small accent circle with a check, on the selected card (a filled Material Symbol shows seams).
Rectangle {
    implicitWidth: 18
    implicitHeight: 18
    radius: width / 2
    color: Theme.accent
    Icon {
        anchors.centerIn: parent
        name: "check"
        size: 14
        color: Theme.accentText
    }
}
