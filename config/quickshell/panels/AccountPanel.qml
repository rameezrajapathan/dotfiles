import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.controlcenter
import qs.lock
import qs.services
import qs.widgets

Item {
    id: root
    property bool shown: false
    signal closeRequested()

    implicitHeight: content.implicitHeight + 40

    onShownChanged: if (shown) User.refresh()

    readonly property var actions: [
        { icon: "lock", title: "Lock", command: ["loginctl", "lock-session"] },
        { icon: "logout", title: "Log out", command: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { icon: "power_settings_new", title: "Power menu", command: ["qs", "ipc", "call", "power", "toggle"] }
    ]

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
        spacing: 4

        Label {
            Layout.bottomMargin: 12
            text: "Account"
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            Item {
                implicitWidth: 96
                implicitHeight: 96

                Avatar {
                    anchors.fill: parent
                    size: 96
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.alpha(Theme.base, 0.55)
                    opacity: pictureMouse.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.ms(120) } }

                    Icon {
                        anchors.centerIn: parent
                        name: "photo_camera"
                        size: 28
                        color: Theme.text
                    }
                }
                MouseArea {
                    id: pictureMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.changePicture()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    Layout.fillWidth: true
                    text: User.displayName
                    font.pixelSize: Theme.fontSize + 6
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: User.userName + (User.hostName ? "@" + User.hostName : "")
                    color: Theme.subtext
                    elide: Text.ElideRight
                }
                RowLayout {
                    Layout.topMargin: 8
                    spacing: 6

                    Pill {
                        text: User.avatar ? "Change picture" : "Add picture"
                        onClicked: root.changePicture()
                    }
                    Pill {
                        visible: User.avatar !== ""
                        icon: "delete"
                        onClicked: User.removePicture()
                    }
                }
            }
        }

        Label {
            Layout.topMargin: 22
            Layout.bottomMargin: 4
            text: "Quick settings"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 2
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
                icon: "sports_esports"
                label: "Game mode"
                detail: active ? "No effects" : "Off"
                active: Toggles.gameMode
                onClicked: Toggles.setGameMode(!Toggles.gameMode)
            }
            ToggleTile {
                icon: "colorize"
                label: "Color picker"
                detail: "Copies hex"
                onClicked: {
                    root.closeRequested();
                    Toggles.pickColor();
                }
            }
        }

        Label {
            Layout.topMargin: 22
            text: "Session"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 2
        }

        Repeater {
            model: root.actions

            Rectangle {
                id: action
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 42
                radius: 12
                color: actionMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Icon { name: action.modelData.icon }
                    Label {
                        Layout.fillWidth: true
                        text: action.modelData.title
                    }
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.closeRequested();
                        Quickshell.execDetached(action.modelData.command);
                    }
                }
            }
        }
    }

    function changePicture() {
        root.closeRequested();
        User.choosePicture();
    }
}
