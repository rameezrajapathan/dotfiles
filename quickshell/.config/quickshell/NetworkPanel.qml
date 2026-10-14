import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Dropdown under the bar: wired status, Wi-Fi networks and VPN connections.
// A transparent full-screen overlay: clicks outside the panel close it.
PanelWindow {
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

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-network"
    color: "transparent"
    visible: false

    onVisibleChanged: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = visible;
        if (visible)
            VpnService.refresh();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
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
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + 6
        anchors.rightMargin: 8
        width: 360
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
                icon: "lan"
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
                Switch {
                    Layout.rightMargin: 8
                    checked: Networking.wifiEnabled
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
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
                        : ""
                    onClicked: root.activate(modelData)

                    Icon {
                        visible: !modelData.connected && !modelData.stateChanging
                            && modelData.security !== WifiSecurityType.Open
                        name: "lock"
                        size: 16
                        color: Theme.subtext
                    }
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
                    id: vpnRow
                    required property var modelData
                    readonly property bool switching: modelData.name in VpnService.pending
                    Layout.fillWidth: true
                    icon: "vpn_key"
                    title: modelData.name
                    highlighted: modelData.active
                    detail: switching ? (VpnService.pending[modelData.name] ? "connecting…" : "disconnecting…")
                        : modelData.active ? "connected" : ""
                    onClicked: VpnService.toggle(modelData.name)

                    Switch {
                        checked: vpnRow.switching ? VpnService.pending[vpnRow.modelData.name] : vpnRow.modelData.active
                        onToggled: VpnService.toggle(vpnRow.modelData.name)
                    }
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
