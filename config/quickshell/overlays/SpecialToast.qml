import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

PanelWindow {
    id: root

    property string name: ""
    property int over: 0
    property bool open: false
    readonly property var info: Special.info(name)

    Connections {
        target: Special
        function onOpened(monitor, name) {
            if (name === "dropterm")
                return;
            const s = Quickshell.screens.find(s => s.name === monitor);
            if (!s)
                return;
            root.screen = s;
            root.name = name;
            root.over = Hyprland.monitors.values.find(m => m.name === monitor)?.activeWorkspace?.id ?? 0;
            root.visible = true;
            root.open = true;
            hideTimer.restart();
        }
    }

    readonly property bool stillShown: name !== "" && Special.on(screen?.name ?? "") === name
    onStillShownChanged: if (!stillShown) open = false

    Timer {
        id: hideTimer
        interval: 2600
        onTriggered: root.open = false
    }

    readonly property string edge: Theme.barPosition
    anchors.top: edge !== "bottom"
    anchors.bottom: edge === "bottom"
    margins.top: (edge === "top" ? Theme.barHeight : 0) + 12
    margins.bottom: (edge === "bottom" ? Theme.barHeight : 0) + 12
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-special"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    implicitWidth: card.implicitWidth
    implicitHeight: 60
    color: "transparent"
    visible: false
    mask: Region {}

    Rectangle {
        id: card
        implicitWidth: row.implicitWidth + 14 + 22
        width: parent.width
        height: parent.height
        radius: Theme.round(height / 2, width, height)
        color: Qt.alpha(Theme.base, 0.92)
        border.width: 1
        border.color: Qt.alpha(Theme.special, 0.5)

        opacity: root.open ? 1 : 0
        y: root.open ? 0 : (root.edge === "bottom" ? 12 : -12)
        Behavior on y { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.ms(180)
                onRunningChanged: if (!running && !root.open) root.visible = false
            }
        }

        RowLayout {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            x: 10
            spacing: 12

            Rectangle {
                implicitWidth: 40
                implicitHeight: 40
                radius: Theme.round(20, width, height)
                color: Theme.special

                Icon {
                    anchors.centerIn: parent
                    name: root.info.icon
                    filled: true
                    size: 22
                    color: Theme.specialText
                }
            }

            ColumnLayout {
                spacing: 0
                Label {
                    text: root.info.label
                    font.bold: true
                }
                Label {
                    text: (root.over > 0 ? `Over workspace ${root.over}` : "Over this workspace")
                        + (root.info.key ? ` · ${root.info.key} hides it` : " · click it in the bar to hide it")
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }
}
