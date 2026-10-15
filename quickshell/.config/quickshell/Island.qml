import QtQuick
import QtQuick.Layouts

// Fully rounded background pill for one group of bar items.
Rectangle {
    default property alias content: row.data
    property alias spacing: row.spacing
    // Space before the first item and after the last
    property real padding: 12

    implicitWidth: row.implicitWidth + 2 * padding
    implicitHeight: Theme.pillHeight
    radius: height / 2
    color: Theme.baseTranslucent

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10
    }
}
