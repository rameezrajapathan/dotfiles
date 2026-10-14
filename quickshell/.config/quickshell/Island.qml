import QtQuick
import QtQuick.Layouts

// Fully rounded background pill for one group of bar items.
Rectangle {
    default property alias content: row.data
    property alias spacing: row.spacing

    implicitWidth: row.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: height / 2
    color: Theme.baseTranslucent

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10
    }
}
