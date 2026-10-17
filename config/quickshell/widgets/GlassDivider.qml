import QtQuick
import qs.services

Rectangle {
    id: root
    property bool vertical: true
    property real strength: 1
    readonly property bool glass: Glass.active

    radius: Math.min(width, height) / 2
    color: glass ? "transparent" : Qt.alpha(Theme.overlay, 0.6 * strength)
    gradient: glass ? fade : null

    readonly property Gradient fade: Gradient {
        orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
        GradientStop { position: 0; color: Qt.alpha(Glass.rimColor, 0.04) }
        GradientStop { position: 0.5; color: Qt.alpha(Glass.rimColor, (Glass.light ? 0.7 : 0.5) * root.strength) }
        GradientStop { position: 1; color: Qt.alpha(Glass.rimColor, 0.04) }
    }

    Rectangle {
        visible: root.glass
        anchors.fill: parent
        anchors.margins: -0.5
        radius: root.radius + 0.5
        color: "transparent"
        border.width: 0.5
        border.color: Qt.alpha(Glass.light ? "black" : "black", Glass.light ? 0.06 : 0.25)
    }
}
