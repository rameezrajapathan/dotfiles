import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    objectName: "settingsRow"
    property string icon
    property string appIcon
    property string title
    property string description
    property bool below: false
    property bool separator: true
    default property alias control: slot.data
    readonly property real controlWidth: slot.children.length ? slot.children[0].implicitWidth : 0
    readonly property bool stacked: below || (controlWidth > 0 && controlWidth > layout.width * 0.45)

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + 24

    function flash() {
        flashAnimation.restart();
    }

    Rectangle {
        id: glow
        anchors.fill: parent
        anchors.margins: 4
        radius: Theme.round(12, width, height)
        color: Theme.accent
        opacity: 0
    }
    SequentialAnimation {
        id: flashAnimation
        loops: 2
        NumberAnimation { target: glow; property: "opacity"; to: 0.22; duration: Theme.ms(260); easing.type: Easing.OutQuad }
        NumberAnimation { target: glow; property: "opacity"; to: 0; duration: Theme.ms(420); easing.type: Easing.InQuad }
    }

    GlassDivider {
        vertical: false
        visible: root.separator && root.parent && root.parent.children[0] !== root
        anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: Theme.pad(62, 16); rightMargin: Theme.pad(16, 16) }
        height: Glass.active ? 2 : 1
        strength: 0.45
    }

    GridLayout {
        id: layout
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Theme.pad(14, 16)
        anchors.rightMargin: Theme.pad(16, 16)
        columns: root.stacked ? 2 : 3
        columnSpacing: 14
        rowSpacing: 12

        Rectangle {
            visible: root.icon !== "" || root.appIcon !== ""
            Layout.alignment: Qt.AlignTop
            implicitWidth: 34
            implicitHeight: 34
            radius: Theme.round(11, width, height)
            color: root.appIcon ? "transparent" : Qt.alpha(Theme.accent, 0.16)

            Icon {
                visible: root.icon !== ""
                anchors.centerIn: parent
                name: root.icon
                size: 19
                color: Theme.accent
            }
            AppIcon {
                visible: root.appIcon !== ""
                anchors.centerIn: parent
                icon: root.appIcon
                implicitSize: 30
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Label {
                Layout.fillWidth: true
                text: root.title
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Label {
                visible: root.description !== ""
                Layout.fillWidth: true
                text: root.description
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 2
                wrapMode: Text.WordWrap
            }
        }

        Item {
            id: slot
            Layout.column: root.stacked ? 1 : 2
            Layout.row: root.stacked ? 1 : 0
            Layout.fillWidth: root.stacked
            Layout.alignment: Qt.AlignVCenter | (root.stacked ? Qt.AlignLeft : Qt.AlignRight)
            implicitWidth: children.length ? children[0].implicitWidth : 0
            implicitHeight: children.length ? children[0].implicitHeight : 0

            Binding {
                when: root.below && slot.children.length > 0
                target: slot.children[0] ?? null
                property: "width"
                value: slot.width
            }
        }
    }
}
