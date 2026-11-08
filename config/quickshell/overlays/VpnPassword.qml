import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

OverlayWindow {
    id: root

    layerNamespace: "quickshell-vpn-password"

    readonly property var request: VpnService.request
    property bool remember: true

    onRequestChanged: {
        if (request) {
            remember = request.remember;
            field.text = "";
            visible = true;
            field.forceActiveFocus();
        }
        open = request !== null;
    }
    onOpenChanged: if (!open && request) VpnService.cancelRequest()

    function submit() {
        if (field.text === "" || VpnService.requestBusy)
            return;
        VpnService.connect(request.uuid, field.text, remember);
        field.text = "";
    }

    Rectangle {
        anchors.centerIn: parent
        width: 420
        height: column.implicitHeight + 48
        radius: Theme.round(26, width, height)
        color: Qt.alpha(Theme.base, 0.94)
        border.width: 1
        border.color: Qt.alpha(Theme.text, 0.1)
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
        GlassRim {}

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
            spacing: 14

            RowLayout {
                spacing: 14
                Rectangle {
                    implicitWidth: 46
                    implicitHeight: 46
                    radius: Theme.round(14, width, height)
                    color: Qt.alpha(Theme.accent, 0.18)
                    Icon {
                        anchors.centerIn: parent
                        name: "vpn_key"
                        filled: true
                        size: 24
                        color: Theme.accent
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        Layout.fillWidth: true
                        text: "Connect to " + (root.request?.name ?? "")
                        font.pixelSize: Theme.fontSize + 3
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Label {
                        visible: (root.request?.username ?? "") !== ""
                        text: "as " + (root.request?.username ?? "")
                        color: Theme.subtext
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: Theme.round(12, width, height)
                color: Qt.alpha(Theme.surface, 0.6)
                border.width: 1
                border.color: VpnService.requestError ? Theme.red : field.activeFocus ? Theme.accent : Qt.alpha(Theme.text, 0.1)

                HoverHandler {
                    cursorShape: Qt.IBeamCursor
                }

                TextInput {
                    id: field
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    readOnly: VpnService.requestBusy
                    focus: root.open
                    onAccepted: root.submit()
                    Keys.onEscapePressed: VpnService.cancelRequest()
                    Label {
                        visible: field.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: VpnService.requestBusy ? "Connecting…" : "Password"
                        color: Theme.overlay
                    }
                }
            }

            Label {
                visible: VpnService.requestError !== ""
                Layout.fillWidth: true
                text: VpnService.requestError
                color: Theme.red
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Switch {
                    checked: root.remember
                    onToggled: root.remember = !checked
                }
                Label {
                    Layout.fillWidth: true
                    text: "Remember the password"
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.remember = !root.remember
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 10
                Item { Layout.fillWidth: true }
                Pill {
                    text: "Cancel"
                    implicitHeight: 38
                    onClicked: VpnService.cancelRequest()
                }
                Pill {
                    text: VpnService.requestBusy ? "Connecting…" : "Connect"
                    active: true
                    implicitHeight: 38
                    onClicked: root.submit()
                }
            }
        }
    }
}
