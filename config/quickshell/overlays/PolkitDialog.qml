import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.services
import qs.widgets

PanelWindow {
    id: root

    readonly property var agent: agentLoader.item
    readonly property var flow: agent?.flow ?? null
    readonly property bool open: (agent?.isActive ?? false) && flow !== null
    property int attempts: 0
    property bool busy: false

    function submit() {
        if (!flow || busy)
            return;
        busy = true;
        flow.submit(input.text);
    }

    function cancel() {
        flow?.cancelAuthenticationRequest();
    }

    LazyLoader {
        id: agentLoader
        active: true
        PolkitAgent {
            onAuthenticationRequestStarted: {
                input.text = "";
                root.busy = false;
            }
        }
    }

    Connections {
        target: root.flow
        function onIsResponseRequiredChanged() {
            if (root.flow.isResponseRequired) {
                root.busy = false;
                input.text = "";
                input.forceActiveFocus();
            }
        }
        function onAuthenticationFailed() {
            root.busy = false;
            input.text = "";
            shake.restart();
        }
    }

    Timer {
        running: true
        interval: 1500
        repeat: true
        onTriggered: {
            if (root.agent?.isRegistered) {
                stop();
            } else if (++root.attempts < 5) {
                agentLoader.active = false;
                agentLoader.active = true;
            } else {
                stop();
                Quickshell.execDetached(["sh", "-c", "pgrep -x hyprpolkitagent >/dev/null || exec /usr/lib/hyprpolkitagent/hyprpolkitagent"]);
            }
        }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-polkit"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: open

    onOpenChanged: if (open) input.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.35
    }

    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 420
        implicitHeight: content.implicitHeight + 48
        radius: 24
        color: Theme.baseTranslucent
        border.width: 1
        border.color: Qt.alpha(Theme.overlay, 0.4)

        transform: Translate { id: shakeOffset }
        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: shakeOffset; property: "x"; to: -10; duration: Theme.ms(50) }
            NumberAnimation { target: shakeOffset; property: "x"; to: 10; duration: Theme.ms(80) }
            NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: Theme.ms(50) }
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 56
                implicitHeight: 56
                radius: 18
                color: Qt.alpha(Theme.accent, 0.18)

                Icon {
                    anchors.centerIn: parent
                    name: "admin_panel_settings"
                    filled: true
                    size: 30
                    color: Theme.accent
                }
            }

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Authentication required"
                font.bold: true
                font.pixelSize: Theme.fontSize + 3
            }

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.flow?.message ?? ""
                color: Theme.subtext
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Avatar {
                    size: 24
                }
                Label {
                    text: User.displayName
                    color: Theme.text
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: 14
                color: Qt.alpha(Theme.base, 0.6)
                border.width: 1
                border.color: root.flow?.supplementaryIsError ? Theme.red : input.activeFocus ? Theme.accent : "transparent"

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    readOnly: root.busy
                    clip: true
                    onAccepted: root.submit()
                    Keys.onEscapePressed: root.cancel()

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
                        color: Theme.overlay
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                visible: text !== ""
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.flow?.supplementaryMessage ?? ""
                color: root.flow?.supplementaryIsError ? Theme.red : Theme.subtext
                font.pixelSize: Theme.fontSize - 1
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 10

                Label {
                    Layout.fillWidth: true
                    text: root.flow?.actionId ?? ""
                    elide: Text.ElideMiddle
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 3
                }
                DialogButton {
                    text: "Cancel"
                    onClicked: root.cancel()
                }
                DialogButton {
                    text: root.busy ? "Checking…" : "Authenticate"
                    primary: true
                    onClicked: root.submit()
                }
            }
        }
    }

    component DialogButton: Rectangle {
        id: button
        property alias text: label.text
        property bool primary: false
        signal clicked()

        implicitWidth: label.implicitWidth + 28
        implicitHeight: 34
        radius: height / 2
        color: primary ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
            : mouse.containsMouse ? Theme.overlay : Theme.surface

        Label {
            id: label
            anchors.centerIn: parent
            color: button.primary ? Theme.accentText : Theme.text
            font.bold: button.primary
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
