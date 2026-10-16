import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.services
import qs.widgets

ColumnLayout {
    id: root
    readonly property var tiles: Settings.controlCenter.tiles

    spacing: 12

    function move(index, delta) {
        const l = tiles.slice();
        const j = index + delta;
        if (j < 0 || j >= l.length)
            return;
        [l[index], l[j]] = [l[j], l[index]];
        Settings.controlCenter.tiles = l;
    }
    function remove(index) {
        const l = tiles.slice();
        l.splice(index, 1);
        Settings.controlCenter.tiles = l;
    }

    Label {
        visible: root.tiles.length === 0
        text: "No tiles: the tiles widgets stay empty."
        color: Theme.overlay
        font.pixelSize: Theme.fontSize - 1
    }

    GridLayout {
        Layout.fillWidth: true
        visible: root.tiles.length > 0
        columns: 3
        rowSpacing: 6
        columnSpacing: 6

        Repeater {
            model: root.tiles

            Rectangle {
                id: tile
                required property string modelData
                required property int index
                readonly property var info: CCStyles.tile(modelData)

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 40
                radius: Theme.round(12, width, height)
                color: hover.hovered ? Qt.alpha(Theme.accent, 0.3) : Qt.alpha(Theme.accent, 0.18)

                HoverHandler { id: hover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.pad(10, 12, parent.width, parent.height)
                    anchors.rightMargin: Theme.pad(6, 12, parent.width, parent.height)
                    spacing: 8

                    Label {
                        text: tile.index + 1
                        color: Theme.overlay
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Icon { name: tile.info.icon; size: 18; color: Theme.accent }
                    Label {
                        Layout.fillWidth: true
                        text: tile.info.label
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSize - 1
                    }
                    Row {
                        visible: hover.hovered
                        spacing: 2
                        BarIconButton {
                            icon: "chevron_left"; size: 16
                            visible: tile.index > 0
                            onClicked: root.move(tile.index, -1)
                        }
                        BarIconButton {
                            icon: "chevron_right"; size: 16
                            visible: tile.index < root.tiles.length - 1
                            onClicked: root.move(tile.index, 1)
                        }
                        BarIconButton {
                            icon: "close"; size: 16
                            color: Theme.red
                            onClicked: root.remove(tile.index)
                        }
                    }
                }
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: CCStyles.tiles.filter(t => !root.tiles.includes(t.id))

            CCAddChip {
                required property var modelData
                icon: modelData.icon
                text: modelData.label
                onClicked: Settings.controlCenter.tiles = root.tiles.concat([modelData.id])
            }
        }
    }
}
