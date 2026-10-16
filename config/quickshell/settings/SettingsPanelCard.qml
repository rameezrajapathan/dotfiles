import QtQuick
import QtQuick.Layouts
import qs.panels
import qs.services

Rectangle {
    id: root
    default property alias panel: holder.data

    Layout.fillWidth: true
    implicitHeight: holder.children.length ? holder.children[0].implicitHeight : 0
    radius: Theme.round(16, width, height)
    color: Qt.alpha(Theme.surface, 0.45)

    Item {
        id: holder
        anchors.fill: parent
        onChildrenChanged: {
            for (const c of children)
                c.width = Qt.binding(() => holder.width);
        }
    }
}
