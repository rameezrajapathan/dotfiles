import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

FloatingWindow {
    id: window
    required property var app

    readonly property bool compact: width < 760
    property bool drawerOpen: false
    onCompactChanged: drawerOpen = false

    title: "Settings"
    implicitWidth: 1040
    implicitHeight: 720
    minimumSize: Qt.size(420, 420)
    color: Qt.alpha(Theme.base, Glass.active ? Glass.value("window") : 0.94)
    onClosed: app.open = false

    function dismiss() {
        if (drawerOpen)
            drawerOpen = false;
        else if (settingsSearch.query !== "")
            sidebar.clearSearch();
        else
            app.open = false;
    }

    function focusSearch() {
        if (compact)
            drawerOpen = true;
        sidebar.focusSearch();
    }

    SettingsSearch {
        id: settingsSearch
        app: window.app
        host: pageHost
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                window.dismiss();
            } else if (event.key === Qt.Key_F && event.modifiers & Qt.ControlModifier) {
                window.focusSearch();
            } else if (event.key === Qt.Key_Tab && event.modifiers & Qt.ControlModifier) {
                settingsSearch.step(1);
            } else if (event.key === Qt.Key_Backtab && event.modifiers & Qt.ControlModifier) {
                settingsSearch.step(-1);
            } else {
                return;
            }
            event.accepted = true;
        }

        SettingsSidebar {
            id: sidebar
            app: window.app
            search: settingsSearch
            anchors { top: parent.top; bottom: parent.bottom }
            z: 2
            width: window.compact ? Math.min(300, window.width - 56) : window.width < 1000 ? 232 : 264
            x: window.compact && !window.drawerOpen ? -width - 1 : 0
            visible: !window.compact || window.drawerOpen || x > -width
            color: window.compact ? Qt.alpha(Theme.base, 0.98) : Qt.alpha(Theme.surface, 0.3)
            Behavior on x { NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutQuint } }
            onNavigated: window.drawerOpen = false
            onEscaped: window.dismiss()
        }

        Rectangle {
            z: 1
            anchors.fill: parent
            color: "black"
            opacity: window.compact && window.drawerOpen ? 0.35 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
            MouseArea {
                anchors.fill: parent
                onClicked: window.drawerOpen = false
            }
        }

        Rectangle {
            id: topBar
            visible: window.compact
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: visible ? 52 : 0
            color: Qt.alpha(Theme.surface, 0.3)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 16
                spacing: 8

                IconButton {
                    icon: "menu"
                    iconSize: 22
                    tone: "flat"
                    rim: true
                    cornerRadius: Theme.round(12, width, height)
                    tip: window.drawerOpen ? "Hide pages" : "Show pages"
                    onClicked: window.drawerOpen = !window.drawerOpen
                }
                Label {
                    Layout.fillWidth: true
                    text: window.app.pages.find(p => p.key === window.app.page)?.title ?? "Settings"
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                IconButton {
                    icon: "search"
                    tone: "flat"
                    rim: true
                    iconColor: Theme.subtext
                    cornerRadius: Theme.round(12, width, height)
                    tip: "Search settings"
                    tipKeys: "Ctrl + F"
                    onClicked: {
                        window.drawerOpen = true;
                        sidebar.focusSearch();
                    }
                }
            }
        }

        SettingsPageHost {
            id: pageHost
            app: window.app
            search: settingsSearch
            compact: window.compact
            anchors { top: topBar.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
            anchors.leftMargin: window.compact ? 0 : sidebar.width
        }
    }
}
