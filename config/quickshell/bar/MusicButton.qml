import QtQuick
import qs.panels
import qs.services
import qs.widgets

Rectangle {
    id: root
    property string icon: ""
    property string glyph: ""
    property bool filled: false
    property bool checked: false
    property real size: 48
    property real glyphSize: size * 0.42
    signal clicked()

    readonly property color fg: filled || checked ? Theme.accentText : Theme.text

    implicitWidth: size
    implicitHeight: size
    radius: mouse.pressed ? size * 0.22 : checked ? size * 0.3 : size / 2
    color: filled || checked ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
        : mouse.containsMouse ? Qt.alpha(Theme.accent, 0.24) : Qt.alpha(Theme.accent, 0.13)
    opacity: enabled ? 1 : 0.4
    Behavior on radius { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
    Behavior on color { ColorAnimation { duration: Theme.ms(150) } }

    Icon {
        visible: root.icon !== ""
        anchors.centerIn: parent
        name: root.icon
        size: root.glyphSize + 2
        color: root.fg
    }
    MediaGlyph {
        visible: root.glyph !== ""
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.glyph === "play" ? size * 0.06 : 0
        kind: root.glyph
        size: root.glyphSize
        color: root.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
