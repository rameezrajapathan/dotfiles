import QtQuick

// Background of a bar pill (or the whole bar); BarLayout.qml places them. A bare one is left
// for a Sheet to draw.
Rectangle {
    property bool bare: false
    y: Theme.barGap
    height: Theme.pillHeight
    radius: Theme.pillRadius
    color: bare ? "transparent" : Theme.baseTranslucent
    border.width: Settings.bar.border && !bare ? 1 : 0
    border.color: Qt.alpha(Theme.overlay, 0.5)
}
