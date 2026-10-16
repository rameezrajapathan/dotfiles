import QtQuick
import QtQuick.Effects
import qs.services

Text {
    id: root
    property string name
    property bool filled: false
    property int size: Theme.iconSize
    property int weight: Theme.iconWeight
    property bool gradientFill: false
    readonly property bool blended: gradientFill && Theme.gradientAccent

    text: name
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": weight, "opsz": Math.min(48, Math.max(20, size)) })

    Loader {
        anchors.fill: parent
        active: root.blended
        sourceComponent: Item {
            Rectangle {
                id: fill
                anchors.fill: parent
                visible: false
                layer.enabled: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.accent }
                    GradientStop { position: 1; color: Theme.accentEnd }
                }
            }
            Text {
                id: mask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                text: root.text
                color: "white"
                verticalAlignment: root.verticalAlignment
                horizontalAlignment: root.horizontalAlignment
                font: root.font
            }
            MultiEffect {
                anchors.fill: parent
                source: fill
                maskEnabled: true
                maskSource: mask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
        }
    }
}
