import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services
import qs.widgets

DesktopWidgetContent {
    id: root
    property string widgetId: ""
    property string screenName: ""
    property bool editing: false

    readonly property bool sample: widgetId === ""
    readonly property var items: sample ? [
        { id: "a", type: "local", target: "~", folder: true },
        { id: "b", type: "web", target: "https://github.com" },
        { id: "c", type: "local", target: "~/Downloads", folder: true },
        { id: "d", type: "web", target: "https://calendar.google.com" }
    ] : Shortcuts.listOf(widgetId)
    readonly property string title: sample ? "" : Shortcuts.titleOf(widgetId)
    readonly property var tiles: editing && !sample ? items.concat([{ id: "+", add: true }]) : items
    readonly property bool tight: width < 120 || height < 120
    readonly property bool showTitle: !tight && (title !== "" || editing)

    ColumnLayout {
        anchors { fill: parent; margins: root.tight ? 8 : 12 }
        spacing: 4

        Item {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            implicitHeight: 22
            visible: root.showTitle

            Label {
                anchors.fill: parent
                visible: !root.editing
                text: root.title
                color: Theme.accent
                font.weight: Font.Bold
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            TextInput {
                id: titleInput
                anchors.fill: parent
                visible: root.editing
                text: root.title
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
                verticalAlignment: Text.AlignVCenter
                clip: true
                selectByMouse: true
                onEditingFinished: if (text.trim() !== root.title) Shortcuts.setTitle(root.widgetId, text)
                Keys.onEscapePressed: {
                    text = root.title;
                    focus = false;
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: titleInput.text === ""
                    text: "Add a title"
                    color: Theme.overlay
                    font.weight: Font.Bold
                }
                HoverHandler {
                    cursorShape: Qt.IBeamCursor
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            FadeMask {
                id: fade
                target: grid
                size: 28
            }

            GridView {
                id: grid
                readonly property int columns: Math.max(1, Math.round(width / 96))
                anchors.fill: parent
                cellWidth: Math.floor(width / columns)
                cellHeight: root.tiles.length <= columns && !root.showTitle ? Math.max(cellWidth, height) : cellWidth
                interactive: !root.editing && contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                model: root.tiles
                layer.enabled: fade.needed
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: fade
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }

                delegate: Item {
                    id: tile
                    required property var modelData
                    readonly property bool adder: modelData.add === true
                    readonly property bool labelled: grid.cellWidth >= 84
                    readonly property string problem: root.editing && !adder ? Shortcuts.problem(modelData) : ""
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: Theme.round(16, width, height)
                        color: Qt.alpha(Theme.text, 0.08)
                        visible: hit.containsMouse && !root.editing
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: icon.size
                            height: icon.size

                            ShortcutIcon {
                                id: icon
                                visible: !tile.adder
                                anchors.fill: parent
                                size: Math.min(64, Math.round(Math.min(grid.cellWidth, grid.cellHeight) * (tile.labelled ? 0.52 : 0.66)))
                                item: tile.adder ? null : tile.modelData
                                warning: tile.problem !== ""
                                scale: hit.pressed ? 0.92 : 1
                                Behavior on scale { NumberAnimation { duration: Theme.ms(90) } }
                            }

                            Rectangle {
                                visible: tile.adder
                                anchors.fill: parent
                                radius: Theme.round(icon.size * 0.26, width, height)
                                color: addMouse.containsMouse ? Qt.alpha(Theme.accent, 0.25) : Qt.alpha(Theme.text, 0.06)
                                border.width: 1.5
                                border.color: Qt.alpha(Theme.text, addMouse.containsMouse ? 0.4 : 0.2)
                                Icon {
                                    anchors.centerIn: parent
                                    name: "add"
                                    size: parent.width * 0.5
                                    color: Theme.text
                                }
                                MouseArea {
                                    id: addMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Shortcuts.edit(root.screenName, root.widgetId, "")
                                }
                                Tooltip {
                                    text: "Add a shortcut"
                                }
                            }
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: tile.labelled
                            width: grid.cellWidth - 10
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.adder ? "Add" : Shortcuts.labelOf(tile.modelData)
                            color: Theme.text
                            font.pixelSize: Theme.fontSize - 2
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: hit
                        anchors.fill: parent
                        enabled: !root.editing && !tile.adder
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: event => {
                            if (root.sample)
                                return;
                            if (event.button === Qt.RightButton) {
                                const p = mapToItem(null, event.x, event.y);
                                Shortcuts.openMenu(root.screenName, root.widgetId, tile.modelData.id, p.x, p.y);
                            } else {
                                Shortcuts.open(tile.modelData);
                            }
                        }
                    }

                    Tooltip {
                        active: !root.editing && !tile.adder && !tile.labelled
                        text: tile.adder ? "" : Shortcuts.labelOf(tile.modelData)
                    }

                    IconButton {
                        visible: root.editing && !tile.adder && !root.sample
                        anchors { top: parent.top; right: parent.right; margins: 2 }
                        width: 26
                        height: 26
                        tone: "solid"
                        icon: "edit"
                        iconSize: 15
                        tip: tile.problem || "Edit"
                        onClicked: Shortcuts.edit(root.screenName, root.widgetId, tile.modelData.id)
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 8
                visible: !root.sample && root.items.length === 0 && !root.editing
                spacing: 6
                Icon {
                    Layout.alignment: Qt.AlignHCenter
                    name: "apps"
                    size: 28
                    color: Theme.overlay
                }
                Label {
                    Layout.fillWidth: true
                    visible: !root.tight
                    horizontalAlignment: Text.AlignHCenter
                    text: "No shortcuts yet"
                    color: Theme.subtext
                    wrapMode: Text.WordWrap
                }
                IconButton {
                    Layout.alignment: Qt.AlignHCenter
                    visible: !root.tight
                    icon: "add"
                    iconSize: 16
                    text: "Add"
                    onClicked: Shortcuts.edit(root.screenName, root.widgetId, "")
                }
            }

            WheelHandler {
                enabled: root.editing
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const dy = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 2;
                    grid.contentY = Math.max(0, Math.min(grid.contentHeight - grid.height, grid.contentY - dy));
                }
            }
        }
    }
}
