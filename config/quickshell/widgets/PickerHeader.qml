import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
    id: root

    property bool expanded: false
    property real leftInset: 10
    default property alias content: slot.data
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 46
    radius: Theme.round(12, width, height)
    color: mouse.containsMouse ? Qt.alpha(Theme.overlay, 0.25) : Qt.alpha(Theme.base, 0.6)
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.pad(root.leftInset, 12, parent.width, parent.height)
        anchors.rightMargin: Theme.pad(12, 12, parent.width, parent.height)
        spacing: 10

        RowLayout {
            id: slot
            Layout.fillWidth: true
            spacing: 10
        }
        Icon {
            name: "expand_more"
            rotation: root.expanded ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutQuint } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
    GlassRim {}
}
