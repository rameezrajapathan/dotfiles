import QtQuick

// Material Symbols Rounded icon by name, e.g. Icon { name: "wifi"; filled: true }.
// Names: https://fonts.google.com/icons (the font turns the name into the icon).
Text {
    property string name
    property bool filled: false
    property int size: Theme.iconSize
    property int weight: 400

    text: name
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": weight, "opsz": Math.min(48, Math.max(20, size)) })
}
