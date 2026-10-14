import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Dropdown of toggle tiles: Do Not Disturb, keep awake, night light and the color picker.
// A transparent full-screen overlay: clicks outside the panel close it.
PanelWindow {
    id: root
    required property var bar

    function toggle() {
        visible = !visible;
    }

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-quicksettings"
    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + 6
        anchors.rightMargin: 8
        width: 390
        height: content.implicitHeight + 28
        color: Theme.baseTranslucent
        radius: 10
        border.color: Theme.surface
        border.width: 2

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10

            Label {
                text: "Quick settings"
                font.bold: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                ToggleTile {
                    icon: "do_not_disturb_on"
                    label: "Do Not Disturb"
                    detail: active ? "Urgent only" : "Off"
                    active: NotificationService.dnd
                    onClicked: NotificationService.dnd = !NotificationService.dnd
                }
                ToggleTile {
                    icon: "coffee"
                    label: "Keep awake"
                    detail: active ? "No lock / sleep" : "Off"
                    active: Toggles.keepAwake
                    onClicked: Toggles.keepAwake = !Toggles.keepAwake
                }
                ToggleTile {
                    icon: "nightlight"
                    label: "Night light"
                    detail: active ? Toggles.nightTemperature + " K" : "Off"
                    active: Toggles.nightLight
                    onClicked: Toggles.nightLight = !Toggles.nightLight
                }
                ToggleTile {
                    icon: "colorize"
                    label: "Color picker"
                    detail: "Copies hex"
                    onClicked: {
                        root.visible = false;
                        Toggles.pickColor();
                    }
                }
            }
        }
    }

    component ToggleTile: Rectangle {
        id: tile
        property string icon
        property string label
        property string detail
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 58
        radius: 14
        color: active ? Theme.accent : tileMouse.containsMouse ? Theme.surface : Qt.alpha(Theme.surface, 0.6)
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            Icon {
                name: tile.icon
                filled: tile.active
                color: tile.active ? Theme.accentText : Theme.text
                size: 22
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    text: tile.label
                    color: tile.active ? Theme.accentText : Theme.text
                    font.bold: true
                    font.pixelSize: Theme.fontSize - 1
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: tile.detail
                    color: tile.active ? Qt.alpha(Theme.accentText, 0.75) : Theme.subtext
                    font.pixelSize: Theme.fontSize - 3
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }
}
