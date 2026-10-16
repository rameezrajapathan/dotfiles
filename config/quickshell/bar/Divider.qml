import QtQuick
import qs.services

Rectangle {
    implicitWidth: Theme.barVertical ? 14 : 1
    implicitHeight: Theme.barVertical ? 1 : 14
    color: Qt.alpha(Theme.overlay, 0.6)
}
