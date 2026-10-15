import QtQuick
import QtQuick.Layouts

// Choose one app from a list: the chosen one with its icon, click to see the others.
// options: [{ id, name, icon }]
ColumnLayout {
    id: root
    property var options: []
    property string current
    property string placeholder: "Not set"
    property bool expanded: false
    signal picked(string id)

    readonly property var chosen: options.find(o => o.id === current) ?? null

    spacing: 6

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 46
        radius: 12
        color: headerMouse.containsMouse ? Qt.alpha(Theme.overlay, 0.25) : Qt.alpha(Theme.base, 0.6)
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10

            AppIcon {
                visible: root.chosen !== null
                icon: root.chosen?.icon ?? ""
            }
            Label {
                Layout.fillWidth: true
                text: root.chosen?.name ?? (root.current ? root.current.replace(/\.desktop$/, "") : root.placeholder)
                color: root.chosen || root.current ? Theme.text : Theme.subtext
                elide: Text.ElideRight
            }
            Label {
                visible: root.options.length > 1
                text: root.options.length + " apps"
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 2
            }
            Icon {
                name: "expand_more"
                rotation: root.expanded ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
            }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: root.expanded ? Math.min(list.contentHeight + 12, 300) : 0
        visible: Layout.preferredHeight > 0
        clip: true
        radius: 12
        color: Qt.alpha(Theme.base, 0.6)
        Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 6
            model: root.options
            spacing: 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool selected: modelData.id === root.current

                width: ListView.view.width
                height: 40
                radius: 9
                color: selected ? Qt.alpha(Theme.accent, 0.2) : rowMouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 10
                    spacing: 10
                    AppIcon { icon: row.modelData.icon; implicitSize: 24 }
                    Label {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        color: row.selected ? Theme.accent : Theme.text
                        elide: Text.ElideRight
                    }
                    Icon {
                        visible: row.selected
                        name: "check_circle"
                        filled: true
                        color: Theme.accent
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.picked(row.modelData.id);
                        root.expanded = false;
                    }
                }
            }
        }
    }
}
