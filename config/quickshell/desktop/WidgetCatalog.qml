import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property bool open: false
    property string screenName: ""
    property string picked: "clock"
    property string sizeClass: "small"
    property string message: ""

    readonly property var kind: Desktop.kind(picked)

    function pick(id) {
        picked = id;
        message = "";
    }

    function add() {
        if (Desktop.add(screenName, picked, size)) {
            message = "";
            Desktop.catalogScreen = "";
        } else {
            message = "There's no room for it. Remove or shrink a widget first.";
        }
    }

    onOpenChanged: message = ""

    anchors.fill: parent
    visible: sheet.opacity > 0

    Rectangle {
        id: sheet
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 980)
        height: Math.min(parent.height - 96, 640)
        radius: Theme.round(28, width, height)
        color: Qt.alpha(Theme.base, 0.95)
        border.width: Glass.active ? 0 : 1
        border.color: Qt.alpha(Theme.text, 0.1)
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
        GlassRim {}

        MouseArea {
            anchors.fill: parent
        }

        RowLayout {
            anchors { fill: parent; margins: 20 }
            spacing: 20

            ColumnLayout {
                Layout.preferredWidth: 300
                Layout.fillWidth: false
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: "Widgets"
                    color: Theme.text
                    font.family: Theme.displayFont
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    Layout.bottomMargin: 8
                    Layout.leftMargin: 6
                }

                ListView {
                    id: kinds
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: Desktop.kinds
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: item
                        required property var modelData
                        readonly property bool selected: root.picked === modelData.id
                        width: kinds.width
                        height: 58
                        radius: Theme.round(14, width, height)
                        color: selected ? Theme.selectedFill : itemMouse.containsMouse ? Qt.alpha(Theme.surface, 0.6) : "transparent"

                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12
                            Rectangle {
                                implicitWidth: 36
                                implicitHeight: 36
                                radius: Theme.round(10, width, height)
                                color: item.selected ? Qt.alpha(Theme.selectedText, 0.15) : Qt.alpha(Theme.accent, 0.15)
                                Icon {
                                    anchors.centerIn: parent
                                    name: item.modelData.icon
                                    size: 20
                                    filled: true
                                    color: item.selected ? Theme.selectedText : Theme.accent
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Label {
                                    text: item.modelData.title
                                    color: item.selected ? Theme.selectedText : Theme.text
                                    font.weight: Font.DemiBold
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: item.modelData.about
                                    color: item.selected ? Qt.alpha(Theme.selectedText, 0.8) : Theme.subtext
                                    font.pixelSize: Theme.fontSize - 2
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pick(item.modelData.id)
                            onDoubleClicked: root.add()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.round(20, width, height)
                color: Qt.alpha(Theme.surface, 0.35)

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: root.kind?.title ?? ""
                                font.pixelSize: Theme.fontSize + 6
                                font.weight: Font.Bold
                            }
                            Label {
                                Layout.fillWidth: true
                                text: root.kind?.about ?? ""
                                color: Theme.subtext
                                wrapMode: Text.WordWrap
                            }
                        }
                        Rectangle {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: 17
                            color: closeMouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.surface, 0.5)
                            Icon { anchors.centerIn: parent; name: "close"; size: 18 }
                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Desktop.catalogScreen = ""
                            }
                        }
                    }

                    Item {
                        id: stage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        DesktopWidget {
                            readonly property real fit: Math.min(1, stage.width / Math.max(1, width), stage.height / Math.max(1, height))
                            preview: true
                            entry: ({ id: "preview", kind: root.picked, size: root.sizeClass, col: 0, row: 0 })
                            readonly property var px: Desktop.pixels(cells.w, cells.h)
                            screenName: root.screenName
                            area: ({ x: (stage.width - px.w) / 2 - Desktop.gutter, y: (stage.height - px.h) / 2 - Desktop.gutter, cols: 99, rows: 99 })
                            live: root.open
                            scale: fit
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: Desktop.sizeOrder
                            Rectangle {
                                id: chip
                                required property string modelData
                                readonly property bool on: root.sizeClass === modelData
                                implicitWidth: chipLabel.implicitWidth + 32
                                implicitHeight: 38
                                radius: height / 2
                                color: on ? Theme.selectedFill : chipMouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.surface, 0.5)
                                Label {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: Desktop.span(chip.modelData).label + "  " + Desktop.dims({ kind: root.picked, size: chip.modelData }).w + "×" + Desktop.dims({ kind: root.picked, size: chip.modelData }).h
                                    color: chip.on ? Theme.selectedText : Theme.text
                                    font.weight: Font.DemiBold
                                }
                                MouseArea {
                                    id: chipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.sizeClass = chip.modelData;
                                        root.message = "";
                                    }
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.message
                            color: Theme.red
                            wrapMode: Text.WordWrap
                            font.pixelSize: Theme.fontSize - 1
                        }

                        Rectangle {
                            implicitWidth: addRow.implicitWidth + 36
                            implicitHeight: 42
                            radius: height / 2
                            color: addMouse.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent
                            Row {
                                id: addRow
                                anchors.centerIn: parent
                                spacing: 6
                                Icon { name: "add"; size: 20; color: Theme.accentText; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: "Add widget"; color: Theme.accentText; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea {
                                id: addMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.add()
                            }
                        }
                    }
                }
            }
        }
    }
}
