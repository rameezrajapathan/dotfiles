import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.controlcenter
import qs.services
import qs.widgets

Item {
    id: root
    property bool shown: false
    signal closeRequested()

    implicitHeight: content.implicitHeight + 40

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifiNetworks: (wifiDevice?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))

    property var passwordTarget: null

    function activate(network) {
        if (network.connected) {
            network.disconnect();
        } else if (network.known || network.security === WifiSecurityType.Open) {
            network.connect();
        } else {
            root.closeRequested();
            passwordTarget = network;
            passwordPrompt.command = ["fuzzel", "--dmenu", "--password", "--lines", "0",
                "--prompt", network.name + " password: "];
            passwordPrompt.running = true;
        }
    }

    function addVpn(mode) {
        root.closeRequested();
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/vpn-add.sh", mode]);
    }

    onShownChanged: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = shown;
        if (shown)
            VpnService.refresh();
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

    Item {
        anchors.fill: parent

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
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
                    icon: SpeedTest.running ? "stop" : "speed"
                    active: SpeedTest.running
                    onClicked: SpeedTest.running ? SpeedTest.cancel() : SpeedTest.start()
                }
                Pill {
                    icon: "settings"
                    onClicked: {
                        root.closeRequested();
                        Apps.terminal(["nmtui"]);
                    }
                }
            }

            NetSpeed {
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                active: root.shown
            }

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
                        icon: "delete"
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

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.rightMargin: 8

                SectionLabel {
                    Layout.fillWidth: true
                    Layout.topMargin: 0
                    text: "VPN"
                }
                Pill {
                    icon: "file_open"
                    onClicked: root.addVpn("import")
                }
                Pill {
                    icon: "add"
                    onClicked: root.addVpn("new")
                }
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

                    Pill {
                        visible: !vpnRow.modelData.active && !vpnRow.switching
                        icon: "delete"
                        onClicked: {
                            root.closeRequested();
                            VpnService.remove(vpnRow.modelData.name);
                        }
                    }
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
