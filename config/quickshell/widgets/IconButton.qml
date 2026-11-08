import QtQuick
import qs.services

Rectangle {
    id: root

    property string icon: ""
    property string text: ""
    property int iconSize: 20
    property bool filled: false
    property string tone: ""
    property bool active: false
    property bool outlined: tone === "solid"
    property bool rim: false
    property real cornerRadius: height / 2
    property string tip: ""
    property string tipKeys: ""
    readonly property bool hovered: mouse.containsMouse
    property color fill: tone === "accent" || active ? (hovered && !active ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
        : tone === "selected" ? Theme.selectedFill
        : tone === "flat" ? (hovered ? Qt.alpha(Theme.surface, 0.8) : "transparent")
        : tone === "solid" ? (hovered ? Qt.lighter(Theme.surface, 1.2) : Theme.surface)
        : Qt.alpha(Theme.surface, hovered ? 0.9 : 0.5)
    property color iconColor: tone === "accent" || active ? Theme.accentText
        : tone === "selected" ? Theme.selectedText
        : Theme.text
    signal clicked()

    implicitWidth: text ? content.implicitWidth + 28 : 36
    implicitHeight: text ? 38 : 36
    radius: cornerRadius
    color: fill
    border.width: outlined ? 1 : 0
    border.color: Qt.alpha(Theme.text, 0.15)

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: root.iconSize
            filled: root.filled
            color: root.iconColor
        }
        Label {
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.iconColor
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Loader {
        anchors.fill: parent
        active: root.rim
        sourceComponent: GlassRim {}
    }

    Tooltip {
        text: root.tip
        keys: root.tipKeys
    }
}
