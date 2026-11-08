import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    required property var app
    required property SettingsSearch search
    signal navigated()
    signal escaped()

    function focusSearch() {
        searchField.focusInput();
    }

    function clearSearch() {
        searchField.clear();
    }

    function jump(hit) {
        navigated();
        root.search.jump(hit);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pad(16, 10)
        anchors.topMargin: Theme.pad(22, 10)
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.bottomMargin: 14
            spacing: 12

            Rectangle {
                implicitWidth: 42
                implicitHeight: 42
                radius: Theme.round(14, width, height)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.lighter(Theme.accent, 1.15) }
                    GradientStop { position: 1; color: Qt.darker(Theme.accent, 1.2) }
                }
                Icon {
                    anchors.centerIn: parent
                    name: "tune"
                    size: 24
                    weight: 500
                    color: Theme.accentText
                }
            }
            ColumnLayout {
                spacing: 0
                Text {
                    text: "Settings"
                    color: Theme.text
                    font.family: Theme.displayFont
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }
                Label {
                    text: "pikadots"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }

        SettingsTextField {
            id: searchField
            Layout.fillWidth: true
            Layout.bottomMargin: 10
            implicitHeight: 38
            cornerRadius: 12
            fill: Qt.alpha(Theme.base, 0.7)
            icon: "search"
            search: true
            placeholder: "Search settings"
            onEdited: t => root.search.query = t
            onAccepted: if (root.search.hits.length) root.jump(root.search.hits[0])
            onStepped: delta => root.search.step(delta)
            onEscaped: root.escaped()
        }

        Flickable {
            id: categoryFlick
            Component.onCompleted: revealTimer.restart()
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: categories.implicitHeight

            Timer {
                id: revealTimer
                interval: 30
                onTriggered: {
                    for (const item of categories.children)
                        if (item.current)
                            categoryFlick.reveal(item);
                }
            }
            Connections {
                target: root.app
                function onPageChanged() {
                    revealTimer.restart();
                }
            }

            function reveal(item) {
                const y = item.mapToItem(categories, 0, 0).y;
                if (y < contentY)
                    contentY = y;
                else if (y + item.height > contentY + height)
                    contentY = Math.min(contentHeight - height, y + item.height - height);
            }
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: categories
                width: parent.width
                spacing: 4

                Label {
                    visible: root.search.hits.length > 0
                    Layout.leftMargin: 12
                    Layout.bottomMargin: 2
                    text: "SETTINGS"
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 3
                    font.bold: true
                    font.letterSpacing: 1.2
                }
                Repeater {
                    model: root.search.hits

                    Rectangle {
                        id: hitRow
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: hitColumn.implicitHeight + 14
                        radius: Theme.round(12, width, height)
                        color: hitMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8)
                            : index === 0 ? Qt.alpha(Theme.accent, 0.12) : "transparent"

                        ColumnLayout {
                            id: hitColumn
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Theme.pad(12, 12, parent.width, parent.height); rightMargin: Theme.pad(12, 12, parent.width, parent.height) }
                            spacing: 0
                            Label {
                                Layout.fillWidth: true
                                text: hitRow.modelData.title
                                elide: Text.ElideRight
                            }
                            Label {
                                Layout.fillWidth: true
                                text: hitRow.modelData.page + (hitRow.index === 0 ? "  ·  ↵" : "")
                                color: Theme.accent
                                font.pixelSize: Theme.fontSize - 3
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: hitMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.jump(hitRow.modelData)
                        }
                        GlassRim {}
                    }
                }
                Item {
                    visible: root.search.hits.length > 0
                    implicitHeight: 8
                }

                Repeater {
                    model: root.search.shownPages

                    ColumnLayout {
                        id: entry
                        required property var modelData
                        required property int index
                        readonly property bool current: root.app.page === modelData.key
                        readonly property bool firstInGroup: index === 0 || root.search.shownPages[index - 1].group !== modelData.group

                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            visible: entry.firstInGroup
                            Layout.leftMargin: 12
                            Layout.topMargin: entry.index === 0 ? 0 : 12
                            Layout.bottomMargin: 2
                            text: entry.modelData.group.toUpperCase()
                            color: Theme.overlay
                            font.pixelSize: Theme.fontSize - 3
                            font.bold: true
                            font.letterSpacing: 1.2
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: Theme.round(13, width, height)
                            color: entry.current ? Theme.selectedFill
                                : rowMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
                            gradient: Theme.accentFill(entry.current)
                            Behavior on color { ColorAnimation { duration: Theme.ms(140) } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.pad(8, 13, parent.width, parent.height)
                                anchors.rightMargin: Theme.pad(12, 13, parent.width, parent.height)
                                spacing: 12

                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: Theme.round(9, width, height)
                                    color: entry.current ? Qt.alpha(Theme.selectedText, 0.14) : Qt.alpha(Theme.selectedFill, 0.16)
                                    Icon {
                                        anchors.centerIn: parent
                                        name: entry.modelData.icon
                                        size: 18
                                        filled: entry.current
                                        color: entry.current ? Theme.selectedText : Theme.selectedFill
                                    }
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: entry.modelData.title
                                    color: entry.current ? Theme.selectedText : Theme.text
                                    font.weight: entry.current ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.app.page = entry.modelData.key;
                                    root.navigated();
                                }
                            }
                        }
                    }
                }

                Label {
                    visible: root.search.shownPages.length === 0 && root.search.hits.length === 0
                    Layout.leftMargin: 12
                    text: "Nothing matches"
                    color: Theme.subtext
                }
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.topMargin: 8
            wrapMode: Text.WordWrap
            text: "ctrl+f search · esc close"
            color: Theme.overlay
            font.pixelSize: Theme.fontSize - 3
        }
    }
}
