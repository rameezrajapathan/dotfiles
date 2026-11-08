import QtQuick

Text {
    required property var theme
    property string name
    property bool filled: false
    property int size: 20
    property int weight: theme.iconWeight ?? 400

    text: name
    color: theme.text
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    font.family: theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": weight, "opsz": Math.min(48, Math.max(20, size)) })
}
