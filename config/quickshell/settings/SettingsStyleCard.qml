import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    property bool selected: false
    property string icon: ""
    property string label: ""
    property string tip: ""
    property real inset: 8
    property real contentSpacing: 8
    readonly property bool hovered: mouse.containsMouse
    default property alias preview: slot.data
    signal clicked()

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: column.implicitHeight + inset * 2
    radius: Theme.round(14, width, height)
    color: selected ? Qt.alpha(Theme.accent, 0.16) : hovered ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.base, 0.45)
    border.width: selected ? 2 : 1
    border.color: Theme.gradientAccent && selected ? "transparent" : selected ? Theme.accent : Qt.alpha(Theme.overlay, 0.25)
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    GradientBorder {
        active: root.selected
    }

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.inset > 0 ? Theme.pad(root.inset, 14, parent.width, parent.height) : 0 }
        spacing: root.contentSpacing

        ColumnLayout {
            id: slot
            Layout.fillWidth: true
            spacing: root.contentSpacing
        }

        RowLayout {
            visible: root.label !== ""
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 6
            Icon {
                visible: root.icon !== ""
                name: root.icon
                size: 17
                filled: root.selected
                color: Theme.accent
            }
            Label {
                Layout.fillWidth: true
                text: root.label
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            CheckBadge {
                visible: root.selected
            }
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

    Tooltip {
        text: root.tip
    }
}
