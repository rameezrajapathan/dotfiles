import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

DesktopWidgetContent {
    id: root

    readonly property var items: Todos.items ?? []
    readonly property int remaining: items.filter(t => !t.done).length

    ColumnLayout {
        anchors { fill: parent; margins: 18 }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Icon {
                name: "checklist"
                size: 18
                color: Theme.accent
            }
            Label {
                Layout.fillWidth: true
                text: "To-do"
                color: Theme.accent
                font.weight: Font.Bold
            }
            Label {
                text: root.remaining > 0 ? root.remaining + " left" : root.items.length ? "All done" : ""
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 2
            }
            Label {
                visible: root.sizeClass !== "small" && root.items.some(t => t.done)
                text: "Clear done"
                color: clearMouse.containsMouse ? Theme.text : Theme.overlay
                font.pixelSize: Theme.fontSize - 2
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Todos.clearDone()
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.items
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: Math.max(30, text.implicitHeight + 10)

                HoverHandler { id: hover }

                Rectangle {
                    id: box
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: row.modelData.done ? Theme.accent : "transparent"
                    border.width: row.modelData.done ? 0 : 2
                    border.color: Theme.overlay
                    Icon {
                        anchors.centerIn: parent
                        visible: row.modelData.done
                        name: "check"
                        size: 15
                        color: Theme.accentText
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Todos.toggle(row.index)
                    }
                }
                Label {
                    id: text
                    anchors { left: box.right; leftMargin: 10; right: remove.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    text: row.modelData.text
                    color: row.modelData.done ? Theme.overlay : Theme.text
                    font.strikeout: row.modelData.done
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Icon {
                    id: remove
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    name: "close"
                    size: 16
                    color: Theme.overlay
                    opacity: hover.hovered ? 1 : 0
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Todos.remove(row.index)
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: root.items.length === 0
                text: "Nothing to do"
                color: Theme.overlay
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: height / 2
            color: Qt.alpha(Theme.surface, input.activeFocus ? 0.8 : 0.45)
            border.width: input.activeFocus ? 1 : 0
            border.color: Theme.accent

            HoverHandler {
                cursorShape: Qt.IBeamCursor
            }

            Icon {
                id: plus
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                name: "add"
                size: 18
                color: Theme.subtext
            }
            TextInput {
                id: input
                anchors { left: plus.right; leftMargin: 6; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                clip: true
                selectByMouse: true
                onAccepted: {
                    Todos.add(text);
                    text = "";
                }
                Keys.onEscapePressed: focus = false
                PointHandler {
                    onActiveChanged: if (active) input.QsWindow.window?.wantKeyboard?.(input)
                }
                Label {
                    visible: input.text === ""
                    text: "Add a task"
                    color: Theme.overlay
                }
            }
        }
    }
}
