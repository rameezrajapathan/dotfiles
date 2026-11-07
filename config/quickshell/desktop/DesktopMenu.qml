import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property bool open: false
    property string screenName: ""
    property point at: Qt.point(0, 0)
    property int current: -1

    readonly property var actions: [
        { icon: "wallpaper", label: "Change wallpaper…", keys: "Super + Shift + W", run: () => Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "toggle"]) },
        { icon: "widgets", label: "Edit widgets…", run: () => Desktop.edit(true) },
        { icon: "add_box", label: "Add a widget…", run: () => Desktop.openCatalog(root.screenName) },
        { icon: Desktop.showing ? "close_fullscreen" : "desktop_windows", label: Desktop.showing ? "Back to windows" : "Show desktop", keys: "Super + H", run: () => { Desktop.showing = !Desktop.showing; } },
        { separator: true },
        { icon: "terminal", label: "Open terminal", keys: "Super + Return", run: () => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/app.sh", "terminal"]) },
        { icon: "monitor", label: "Display settings", run: () => Settings.openRequested("displays") },
        { icon: "settings", label: "Pikadots settings", keys: "Super + ,", run: () => Settings.openRequested("") }
    ]

    function run(a) {
        Desktop.menu = null;
        a.run();
    }

    onOpenChanged: current = -1

    anchors.fill: parent
    visible: card.opacity > 0

    Rectangle {
        id: card
        readonly property real w: 310
        x: Math.max(8, Math.min(root.at.x, root.width - w - 8))
        y: Math.max(8, Math.min(root.at.y, root.height - height - 8))
        width: w
        height: list.implicitHeight + 12
        radius: Theme.round(16, width, height)
        color: Theme.denseTranslucent
        border.width: Glass.active ? 0 : 1
        border.color: Qt.alpha(Theme.text, 0.1)
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        transformOrigin: Item.TopLeft
        Behavior on opacity { NumberAnimation { duration: Theme.ms(120) } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }
        GlassRim {}

        MouseArea {
            anchors.fill: parent
        }

        Item {
            anchors.fill: parent
            focus: root.open
            Keys.onUpPressed: root.current = root.step(-1)
            Keys.onDownPressed: root.current = root.step(1)
            Keys.onReturnPressed: if (root.current >= 0) root.run(root.actions[root.current])
            Keys.onEscapePressed: Desktop.menu = null
        }

        ColumnLayout {
            id: list
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            spacing: 0

            Repeater {
                model: root.actions
                Item {
                    id: row
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: modelData.separator ? 9 : 36

                    Rectangle {
                        visible: row.modelData.separator === true
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Qt.alpha(Theme.text, 0.1)
                    }

                    Rectangle {
                        visible: !row.modelData.separator
                        anchors.fill: parent
                        radius: Theme.round(10, width, height)
                        color: root.current === row.index ? Theme.selectedFill : "transparent"

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 10
                            Icon {
                                name: row.modelData.icon ?? ""
                                size: 18
                                color: root.current === row.index ? Theme.selectedText : Theme.subtext
                            }
                            Label {
                                Layout.fillWidth: true
                                text: row.modelData.label ?? ""
                                color: root.current === row.index ? Theme.selectedText : Theme.text
                                elide: Text.ElideRight
                            }
                            Label {
                                text: row.modelData.keys ?? ""
                                color: root.current === row.index ? Theme.selectedText : Theme.overlay
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.current = row.index
                            onClicked: root.run(row.modelData)
                        }
                    }
                }
            }
        }
    }

    function step(d) {
        let i = current;
        for (let n = 0; n < actions.length; n++) {
            i = (i + d + actions.length) % actions.length;
            if (!actions[i].separator)
                return i;
        }
        return current;
    }
}
