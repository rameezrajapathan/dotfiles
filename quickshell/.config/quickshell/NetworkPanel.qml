import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

// Dropdown under the bar: wired status, Wi-Fi networks and VPN connections.
PopupWindow {
    id: root
    required property var bar

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifiNetworks: (wifiDevice?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))

    property var passwordTarget: null

    function toggle() {
        visible = !visible;
    }

    function activate(network) {
        if (network.connected) {
            network.disconnect();
        } else if (network.known || network.security === WifiSecurityType.Open) {
            network.connect();
        } else {
            passwordTarget = network;
            passwordPrompt.command = ["fuzzel", "--dmenu", "--password", "--lines", "0",
                "--prompt", network.name + " password: "];
            passwordPrompt.running = true;
        }
    }

    anchor.window: bar
    anchor.rect.x: bar.width - implicitWidth - 8
    anchor.rect.y: bar.height + 6
    implicitWidth: 360
    implicitHeight: content.implicitHeight + 28
    color: "transparent"
    visible: false

    onVisibleChanged: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = visible;
        if (visible)
            VpnService.refresh();
    }

    // Close when clicking anywhere outside the panel and the bar.
    HyprlandFocusGrab {
        active: root.visible
        windows: [root, root.bar]
        onCleared: root.visible = false
    }

    Process {
        id: passwordPrompt
        stdout: StdioCollector {
            onStreamFinished: {
                const password = text.replace(/\n$/, "");
                if (password && root.passwordTarget)
                    root.passwordTarget.connectWithPsk(password);
                root.passwordTarget = null;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.base
        radius: 10
        border.color: Theme.surface
        border.width: 2

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4

                Label {
                    Layout.fillWidth: true
                    text: "Network"
                    font.bold: true
                }
                Pill {
                    text: "settings"
                    onClicked: {
                        root.visible = false;
                        Quickshell.execDetached(["kitty", "-e", "nmtui"]);
                    }
                }
            }

            // Wired
            SectionLabel {
                text: "Wired"
                visible: root.wiredDevice !== null
            }
            PanelRow {
                Layout.fillWidth: true
                visible: root.wiredDevice !== null
                clickable: false
                icon: "󰈀"
                title: root.wiredDevice?.name ?? ""
                highlighted: root.wiredDevice?.connected ?? false
                detail: !root.wiredDevice?.connected ? "disconnected"
                    : root.wiredDevice.linkSpeed > 0 ? root.wiredDevice.linkSpeed + " Mb/s" : "connected"
            }

            // Wi-Fi
            RowLayout {
                Layout.fillWidth: true
                visible: root.wifiDevice !== null

                SectionLabel {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                }
                Pill {
                    text: Networking.wifiEnabled ? "on" : "off"
                    active: Networking.wifiEnabled
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            Label {
                visible: root.wifiDevice !== null && (!Networking.wifiEnabled || root.wifiNetworks.length === 0)
                Layout.leftMargin: 8
                text: Networking.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
                color: Theme.overlay
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 8 * 34)
                visible: Networking.wifiEnabled && count > 0
                clip: true
                spacing: 2
                model: root.wifiNetworks

                delegate: PanelRow {
                    required property var modelData
                    width: ListView.view.width
                    icon: Theme.wifiIcon(modelData.signalStrength)
                    title: modelData.name
                    highlighted: modelData.connected
                    detail: modelData.stateChanging ? "connecting…"
                        : modelData.connected ? "connected"
                        : modelData.security !== WifiSecurityType.Open ? "󰌾" : ""
                    onClicked: root.activate(modelData)

                    Pill {
                        visible: modelData.known && !modelData.connected
                        text: "forget"
                        onClicked: modelData.forget()
                    }

                    Connections {
                        target: modelData
                        function onConnectionFailed(reason) {
                            Quickshell.execDetached(["notify-send", "-u", "critical", "Wi-Fi",
                                "Couldn't connect to " + modelData.name + " (" + ConnectionFailReason.toString(reason) + ")"]);
                        }
                    }
                }
            }

            // VPN
            SectionLabel {
                text: "VPN"
            }
            Label {
                visible: VpnService.connections.length === 0
                Layout.leftMargin: 8
                text: "No VPN connections"
                color: Theme.overlay
            }
            Repeater {
                model: VpnService.connections

                PanelRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: "󰖂"
                    title: modelData.name
                    highlighted: modelData.active
                    detail: modelData.active ? "connected" : ""
                    onClicked: VpnService.toggle(modelData.name)
                }
            }
        }
    }

    component SectionLabel: Label {
        Layout.topMargin: 6
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 2
    }
}
