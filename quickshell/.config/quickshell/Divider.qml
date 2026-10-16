import QtQuick

// Thin line between groups in a bar island: upright, or flat on a side bar.
Rectangle {
    implicitWidth: Theme.barVertical ? 14 : 1
    implicitHeight: Theme.barVertical ? 1 : 14
    color: Qt.alpha(Theme.overlay, 0.6)
}
