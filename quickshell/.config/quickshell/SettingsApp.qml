import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// The Settings app: a normal window (floats centered, rules.lua) with categories on the left and
// one page at a time on the right. Super + Comma, the gear in the control center, the launcher
// entry, or `qs ipc call settings open <page|"">`. Choices are saved by Settings.qml.
// The window only exists while it's open.
Scope {
    id: root

    property bool open: false
    property string page: "appearance"

    readonly property var pages: [
        { key: "appearance", group: "Personalize", title: "Appearance", icon: "palette",
            keywords: "wallpaper colors theme dark light mode palette scheme transparency opacity", component: appearancePage },
        { key: "fonts", group: "Personalize", title: "Fonts & icons", icon: "font_download",
            keywords: "font typeface text size icons weight", component: fontsPage },
        { key: "bar", group: "Personalize", title: "Bar", icon: "toolbar",
            keywords: "bar pill height weather music spectrum clock 24 hour seconds", component: barPage },
        { key: "about", group: "System", title: "About", icon: "info",
            keywords: "about version system hyprland quickshell kernel memory cpu", component: aboutPage }
    ]

    function show(key) {
        if (key && pages.some(p => p.key === key))
            page = key;
        if (open)
            Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.focus({ window = "title:^Settings$" })']);
        open = true;
    }

    Connections {
        target: Settings
        function onOpenRequested(key) {
            root.show(key);
        }
    }

    LazyLoader {
        active: root.open

        FloatingWindow {
            id: window
            title: "Settings"
            implicitWidth: 1040
            implicitHeight: 720
            minimumSize: Qt.size(780, 520)
            color: Qt.alpha(Theme.base, 0.94)
            onClosed: root.open = false

            // Pages matching the search (all of them while it's empty)
            readonly property var shownPages: {
                const words = search.text.toLowerCase().split(/\s+/).filter(w => w);
                return root.pages.filter(p => words.every(w => (p.title + " " + p.keywords).toLowerCase().includes(w)));
            }

            function step(delta) {
                const list = shownPages.length ? shownPages : root.pages;
                const i = list.findIndex(p => p.key === root.page);
                root.page = list[(i + delta + list.length) % list.length].key;
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (search.text !== "")
                            search.text = "";
                        else
                            root.open = false;
                    } else if (event.key === Qt.Key_F && event.modifiers & Qt.ControlModifier) {
                        search.forceActiveFocus();
                    } else if (event.key === Qt.Key_Tab && event.modifiers & Qt.ControlModifier) {
                        window.step(1);
                    } else if (event.key === Qt.Key_Backtab && event.modifiers & Qt.ControlModifier) {
                        window.step(-1);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                // Sidebar
                Rectangle {
                    id: sidebar
                    anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                    width: 264
                    color: Qt.alpha(Theme.surface, 0.3)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        anchors.topMargin: 22
                        spacing: 4

                        // App title
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Layout.bottomMargin: 14
                            spacing: 12

                            Rectangle {
                                implicitWidth: 42
                                implicitHeight: 42
                                radius: 14
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

                        // Search
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 10
                            implicitHeight: 38
                            radius: 12
                            color: Qt.alpha(Theme.base, 0.7)
                            border.width: search.activeFocus ? 1 : 0
                            border.color: Theme.accent

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
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
                                    // The first match opens as you type
                                    onTextChanged: if (window.shownPages.length && !window.shownPages.some(p => p.key === root.page))
                                        root.page = window.shownPages[0].key
                                    Keys.onDownPressed: window.step(1)
                                    Keys.onUpPressed: window.step(-1)

                                    Label {
                                        visible: !search.text
                                        text: "Search settings"
                                        color: Theme.overlay
                                    }
                                }
                            }
                        }

                        // Categories, under their group names
                        Repeater {
                            model: window.shownPages

                            ColumnLayout {
                                id: entry
                                required property var modelData
                                required property int index
                                readonly property bool current: root.page === modelData.key
                                readonly property bool firstInGroup: index === 0 || window.shownPages[index - 1].group !== modelData.group

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
                                    implicitHeight: 42
                                    radius: 13
                                    color: entry.current ? Theme.accent
                                        : rowMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 12
                                        spacing: 12

                                        Rectangle {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            radius: 9
                                            color: entry.current ? Qt.alpha(Theme.accentText, 0.14) : Qt.alpha(Theme.accent, 0.16)
                                            Icon {
                                                anchors.centerIn: parent
                                                name: entry.modelData.icon
                                                size: 18
                                                filled: entry.current
                                                color: entry.current ? Theme.accentText : Theme.accent
                                            }
                                        }
                                        Label {
                                            Layout.fillWidth: true
                                            text: entry.modelData.title
                                            color: entry.current ? Theme.accentText : Theme.text
                                            font.weight: entry.current ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: rowMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.page = entry.modelData.key
                                    }
                                }
                            }
                        }

                        Label {
                            visible: window.shownPages.length === 0
                            Layout.leftMargin: 12
                            text: "Nothing matches"
                            color: Theme.subtext
                        }

                        Item { Layout.fillHeight: true }

                        Label {
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            wrapMode: Text.WordWrap
                            text: "ctrl+f search · esc close"
                            color: Theme.overlay
                            font.pixelSize: Theme.fontSize - 3
                        }
                    }
                }

                // Pages; each is built the first time it's opened and keeps its scroll position
                Item {
                    anchors { top: parent.top; bottom: parent.bottom; left: sidebar.right; right: parent.right }

                    Repeater {
                        model: root.pages

                        Flickable {
                            id: flick
                            required property var modelData
                            readonly property bool current: root.page === modelData.key
                            property bool visited: false
                            onCurrentChanged: if (current) visited = true
                            Component.onCompleted: visited = current

                            anchors.fill: parent
                            opacity: current ? 1 : 0
                            visible: opacity > 0
                            transform: Translate {
                                y: flick.current ? 0 : 12
                                Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutQuint } }
                            }
                            Behavior on opacity { NumberAnimation { duration: flick.current ? 220 : 70 } }
                            clip: true
                            contentWidth: width
                            contentHeight: loader.height + 72
                            boundsBehavior: Flickable.StopAtBounds

                            Loader {
                                id: loader
                                active: flick.visited
                                x: 40
                                y: 36
                                // Readable line length on wide windows
                                width: Math.min(flick.width - 80, 820)
                                height: item?.implicitHeight ?? 0
                                sourceComponent: flick.modelData.component
                            }
                            Binding {
                                target: loader.item
                                property: "shown"
                                value: flick.current
                            }
                        }
                    }
                }
            }
        }
    }

    Component { id: appearancePage; SettingsAppearancePage {} }
    Component { id: fontsPage; SettingsFontsPage {} }
    Component { id: barPage; SettingsBarPage {} }
    Component { id: aboutPage; SettingsAboutPage {} }
}
