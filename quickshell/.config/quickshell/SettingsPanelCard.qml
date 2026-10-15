import QtQuick
import QtQuick.Layouts

// Shows one of the control center's panels (NetworkPanel, AudioPanel, ...) on a Settings page card,
// so both places share one implementation. Put the panel inside.
Rectangle {
    id: root
    default property alias panel: holder.data

    Layout.fillWidth: true
    implicitHeight: holder.children.length ? holder.children[0].implicitHeight : 0
    radius: 16
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
