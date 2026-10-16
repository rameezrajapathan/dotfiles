import QtQuick

// Round-cornered square icon button for the control center. `tone`: "" (surface), "accent",
// "danger" or "flat" (no background until hovered).
Rectangle {
    id: root
    property string icon
    property string tone: ""
    property bool filled: false
    property int iconSize: 20
    property int badge: 0
    signal clicked()
    signal rightClicked()

    implicitWidth: 36
    implicitHeight: 36
    radius: Math.min(12, height / 3)
    color: tone === "accent" ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
        : tone === "danger" ? Qt.alpha(Theme.red, mouse.containsMouse ? 0.3 : 0.16)
        : tone === "flat" ? (mouse.containsMouse ? Qt.alpha(Theme.surface, 0.7) : "transparent")
        : Qt.alpha(Theme.surface, mouse.containsMouse ? 0.85 : 0.55)
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        filled: root.filled
        color: root.tone === "accent" ? Theme.accentText : root.tone === "danger" ? Theme.red : Theme.text
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }

    Rectangle {
        visible: root.badge > 0
        anchors { top: parent.top; right: parent.right; topMargin: 1; rightMargin: 1 }
        height: 15
        width: Math.max(height, badgeText.implicitWidth + 8)
        radius: height / 2
        color: Theme.accent

        Label {
            id: badgeText
            anchors.centerIn: parent
            text: root.badge > 99 ? "99+" : root.badge
            color: Theme.accentText
            font.pixelSize: 9
            font.bold: true
        }
    }
}
