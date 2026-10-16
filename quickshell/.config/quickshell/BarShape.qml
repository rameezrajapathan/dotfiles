import QtQuick

// Background of a bar pill (or the whole bar); BarLayout.qml places them along the bar (`along`,
// `size`: x and width on a top or bottom bar, y and height on a side one). A bare one is left
// for a Sheet to draw.
Rectangle {
    property bool bare: false
    property real along: 0
    property real size: 0
    readonly property bool vertical: Theme.barVertical
    x: vertical ? Theme.barGap : along
    y: vertical ? along : Theme.barGap
    width: vertical ? Theme.pillHeight : size
    height: vertical ? size : Theme.pillHeight
    radius: Theme.pillRadius
    color: bare ? "transparent" : Theme.baseTranslucent
    border.width: Settings.bar.border && !bare ? 1 : 0
    border.color: Qt.alpha(Theme.overlay, 0.5)
}
