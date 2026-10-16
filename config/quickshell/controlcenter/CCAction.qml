import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: action
    property string icon
    property string text
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 42
    radius: Theme.round(14, width, height)
    color: Qt.alpha(Theme.surface, mouse.containsMouse ? 0.85 : 0.55)
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    Row {
        anchors.centerIn: parent
        spacing: 6
        Icon { anchors.verticalCenter: parent.verticalCenter; name: action.icon; size: 18 }
        Label { anchors.verticalCenter: parent.verticalCenter; text: action.text; font.pixelSize: Theme.fontSize - 1 }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: action.clicked()
    }
}
