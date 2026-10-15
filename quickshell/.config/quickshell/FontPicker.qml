import QtQuick
import QtQuick.Layouts

// Installed font families, each shown in its own face; type to filter. Used under a SettingsRow.
ColumnLayout {
    id: root
    property string current
    // Monospace-only list, for terminal-like uses
    property bool monospace: false
    property string sample: "The quick brown fox jumps over the lazy dog · 0123456789"
    property bool expanded: false
    signal picked(string family)

    readonly property var families: {
        // Skip the style-specific duplicates fontconfig lists ("Fira Sans Compressed Book")
        const seen = new Set();
        return Qt.fontFamilies().filter(f => {
            if (f.startsWith(".") || /\b(Book|Eight|Four|Two|Hair|Heavy|Thin|Light|Medium|SemiBold|ExtraBold|ExtraLight|UltraLight|Black|Mono SemiBold)$/.test(f))
                return false;
            if (seen.has(f))
                return false;
            // Name-based: Qt can't tell fixed-pitch families apart here
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

    // The current font; click to open the list
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 56
        radius: 12
        color: headerMouse.containsMouse ? Qt.alpha(Theme.overlay, 0.25) : Qt.alpha(Theme.base, 0.6)
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
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
                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
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
        radius: 12
        color: Qt.alpha(Theme.base, 0.6)
        Behavior on Layout.preferredHeight { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Search
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 10
                color: Qt.alpha(Theme.surface, 0.8)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
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
                    radius: 10
                    color: selected ? Qt.alpha(Theme.accent, 0.2)
                        : rowMouse.containsMouse || ListView.isCurrentItem ? Qt.alpha(Theme.surface, 0.9) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
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
