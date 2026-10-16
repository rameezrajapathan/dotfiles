import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

ColumnLayout {
    id: root
    property string current
    property bool monospace: false
    property string sample: "The quick brown fox jumps over the lazy dog · 0123456789"
    property bool expanded: false
    signal picked(string family)

    readonly property var families: {
        const seen = new Set();
        return Qt.fontFamilies().filter(f => {
            if (f.startsWith(".") || /\b(Book|Eight|Four|Two|Hair|Heavy|Thin|Light|Medium|SemiBold|ExtraBold|ExtraLight|UltraLight|Black|Mono SemiBold)$/.test(f))
                return false;
            if (seen.has(f))
                return false;
            if (root.monospace && !/mono|hack|iosevka|code|courier|consol|fixed|terminal/i.test(f))
                return false;
            seen.add(f);
            return true;
        });
    }
    readonly property var shown: {
        const words = search.text.toLowerCase().split(/\s+/).filter(w => w);
        return families.filter(f => words.every(w => f.toLowerCase().includes(w)));
    }

    spacing: 8

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 56
        radius: Theme.round(12, width, height)
        color: headerMouse.containsMouse ? Qt.alpha(Theme.overlay, 0.25) : Qt.alpha(Theme.base, 0.6)
        Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.pad(14, 12, parent.width, parent.height)
            anchors.rightMargin: Theme.pad(12, 12, parent.width, parent.height)
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: root.current
                    color: Theme.text
                    font.family: root.current
                    font.pixelSize: Theme.fontSize + 3
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.sample
                    color: Theme.subtext
                    font.family: root.current
                    font.pixelSize: Theme.fontSize - 1
                    elide: Text.ElideRight
                }
            }
            Icon {
                name: "expand_more"
                rotation: root.expanded ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutQuint } }
            }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.expanded = !root.expanded;
                if (root.expanded) {
                    search.text = "";
                    search.forceActiveFocus();
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: root.expanded ? 330 : 0
        visible: Layout.preferredHeight > 0
        clip: true
        radius: Theme.round(12, width, height)
        color: Qt.alpha(Theme.base, 0.6)
        Behavior on Layout.preferredHeight { NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutQuint } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.pad(8, 12, parent.width, parent.height)
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.round(10, width, height)
                color: Qt.alpha(Theme.surface, 0.8)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.pad(10, 10, parent.width, parent.height)
                    anchors.rightMargin: Theme.pad(10, 10, parent.width, parent.height)
                    spacing: 8
                    Icon { name: "search"; size: 18; color: Theme.subtext }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentText
                        clip: true
                        Keys.onEscapePressed: root.expanded = false
                        Keys.onReturnPressed: if (root.shown.length) root.picked(root.shown[list.currentIndex >= 0 ? list.currentIndex : 0])
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()

                        Label {
                            visible: !search.text
                            text: root.families.length + " fonts — type to filter"
                            color: Theme.overlay
                        }
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.shown
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 120
                currentIndex: -1

                delegate: Rectangle {
                    id: fontRow
                    required property string modelData
                    required property int index
                    readonly property bool selected: modelData === root.current

                    width: ListView.view.width
                    height: 50
                    radius: Theme.round(10, width, height)
                    color: selected ? Qt.alpha(Theme.accent, 0.2)
                        : rowMouse.containsMouse || ListView.isCurrentItem ? Qt.alpha(Theme.surface, 0.9) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.pad(12, 10, parent.width, parent.height)
                        anchors.rightMargin: Theme.pad(12, 10, parent.width, parent.height)
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Label {
                                Layout.fillWidth: true
                                text: fontRow.modelData
                                color: fontRow.selected ? Theme.accent : Theme.subtext
                                font.pixelSize: Theme.fontSize - 3
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.sample
                                color: Theme.text
                                font.family: fontRow.modelData
                                font.pixelSize: Theme.fontSize + 2
                                elide: Text.ElideRight
                            }
                        }
                        Icon {
                            visible: fontRow.selected
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
                        onClicked: root.picked(fontRow.modelData)
                    }
                }
            }
        }
    }
}
