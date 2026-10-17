import QtQuick
import qs.services
import qs.widgets

GlassDivider {
    vertical: !Theme.barVertical
    implicitWidth: Theme.barVertical ? 16 : (Glass.active ? 3 : 1)
    implicitHeight: Theme.barVertical ? (Glass.active ? 3 : 1) : 16
}
