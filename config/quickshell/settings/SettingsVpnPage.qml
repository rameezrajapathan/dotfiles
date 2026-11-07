import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "VPN"
    subtitle: "Connect, see why a connection failed, and change servers, sign-in, routing and certificates."

    Component.onCompleted: VpnService.refresh()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function since(t) {
        if (!t)
            return "";
        const mins = Math.max(0, Math.round((clock.date.getTime() / 1000 - t) / 60));
        return mins < 1 ? "just now" : mins < 60 ? "for " + mins + " min" : "for " + Math.floor(mins / 60) + " h " + (mins % 60) + " min";
    }

    function fileName(path) {
        return path ? path.slice(path.lastIndexOf("/") + 1) : "none";
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Pill {
            text: "Import a file…"
            tip: ".ovpn (OpenVPN) or .conf (WireGuard)"
            implicitHeight: 34
            onClicked: VpnService.add("import")
        }
        Pill {
            text: "New VPN…"
            tip: "Other kinds (L2TP, IPsec, …) through NetworkManager"
            implicitHeight: 34
            onClicked: VpnService.add("new")
        }
        Item { Layout.fillWidth: true }
        Label {
            visible: VpnService.loading
            text: "Refreshing…"
            color: Theme.overlay
            font.pixelSize: Theme.fontSize - 2
        }
    }

    Label {
        visible: VpnService.connections.length === 0
        Layout.fillWidth: true
        text: "No VPN yet. Import the .ovpn or WireGuard file your company or provider gave you."
        color: Theme.subtext
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: VpnService.details

        SettingsSection {
            id: vpn
            required property var modelData
            readonly property string uuid: modelData.uuid
            readonly property bool busy: uuid in VpnService.pending
            readonly property string error: VpnService.errors[uuid] ?? modelData.error ?? ""
            property bool confirmRemove: false
            property bool logOpen: false

            title: modelData.name
            subtitle: (modelData.kind === "openvpn" ? "OpenVPN" : modelData.kind === "wireguard" ? "WireGuard" : modelData.kind)
                + (modelData.active ? "  ·  changes apply the next time you connect" : "")

            SettingsRow {
                icon: vpn.modelData.active ? "vpn_lock" : vpn.error ? "error" : "vpn_key_off"
                title: vpn.busy ? (VpnService.pending[vpn.uuid] ? "Connecting…" : "Disconnecting…")
                    : vpn.modelData.active ? "Connected" : vpn.error ? "Couldn't connect" : "Not connected"
                description: vpn.modelData.active ? [vpn.modelData.address, root.since(vpn.modelData.since)].filter(s => s).join("  ·  ")
                    : vpn.error
                Pill {
                    text: vpn.modelData.active ? "Disconnect" : "Connect"
                    active: !vpn.modelData.active
                    implicitHeight: 32
                    onClicked: vpn.modelData.active ? VpnService.disconnect(vpn.uuid) : VpnService.connect(vpn.uuid)
                }
            }
            SettingsRow {
                visible: !vpn.modelData.active && vpn.modelData.hint === "compat" && !vpn.modelData.compat
                icon: "tips_and_updates"
                title: "Try compatibility with older servers"
                description: "Allows older TLS versions and weaker certificates, which some firewalls still use."
                Pill {
                    text: "Turn on"
                    implicitHeight: 32
                    onClicked: VpnService.set(vpn.uuid, "compat", "yes")
                }
            }

            SettingsRow {
                icon: "badge"
                title: "Name"
                SettingsTextField {
                    implicitWidth: 280
                    text: vpn.modelData.name
                    onAccepted: t => t.trim() && t !== vpn.modelData.name && VpnService.set(vpn.uuid, "name", t)
                }
            }
            SettingsRow {
                visible: vpn.modelData.editable === true
                icon: "dns"
                title: "Servers"
                description: "Tried in order: address:port:protocol, separated by commas."
                below: true
                SettingsTextField {
                    Layout.fillWidth: true
                    implicitWidth: 520
                    text: (vpn.modelData.servers ?? []).join(", ")
                    onAccepted: t => VpnService.set(vpn.uuid, "servers", t)
                }
            }
            SettingsRow {
                visible: vpn.modelData.usesPassword === true
                icon: "person"
                title: "Username"
                SettingsTextField {
                    implicitWidth: 280
                    text: vpn.modelData.username ?? ""
                    onAccepted: t => VpnService.set(vpn.uuid, "username", t)
                }
            }
            SettingsRow {
                visible: vpn.modelData.usesPassword === true && !vpn.modelData.askPassword
                icon: "password"
                title: "Password"
                description: vpn.modelData.passwordSaved ? "Saved. Type a new one to replace it." : "Not saved yet; you'll be asked when connecting."
                SettingsTextField {
                    id: pass
                    implicitWidth: 280
                    secret: true
                    placeholder: vpn.modelData.passwordSaved ? "••••••••" : "Password"
                    onEntered: t => {
                        if (t) {
                            VpnService.setPassword(vpn.uuid, t);
                            pass.clear();
                        }
                    }
                }
            }
            SettingsRow {
                visible: vpn.modelData.usesPassword === true
                icon: "lock_clock"
                title: "Ask for the password every time"
                description: "Nothing is saved; for one-time codes or shared computers."
                Switch {
                    checked: vpn.modelData.askPassword === true
                    onToggled: VpnService.set(vpn.uuid, "askPassword", checked ? "no" : "yes")
                }
            }
            SettingsRow {
                icon: "alt_route"
                title: "Send all traffic through the VPN"
                description: vpn.modelData.allTraffic ? "Everything goes through the VPN." : "Only the VPN's own networks do; the rest uses your normal connection."
                Switch {
                    checked: vpn.modelData.allTraffic === true
                    onToggled: VpnService.set(vpn.uuid, "allTraffic", checked ? "no" : "yes")
                }
            }
            SettingsRow {
                icon: "dns"
                title: "DNS servers"
                description: "For company names that only resolve inside the VPN. Empty uses what the server sends."
                SettingsTextField {
                    implicitWidth: 280
                    text: vpn.modelData.dns ?? ""
                    placeholder: "e.g. 10.0.0.1 10.0.0.2"
                    onAccepted: t => VpnService.set(vpn.uuid, "dns", t)
                }
            }
            SettingsRow {
                icon: "travel_explore"
                title: "Search domains"
                description: "So short names like intranet work."
                SettingsTextField {
                    implicitWidth: 280
                    text: vpn.modelData.search ?? ""
                    placeholder: "e.g. corp.example.com"
                    onAccepted: t => VpnService.set(vpn.uuid, "search", t)
                }
            }
            SettingsRow {
                icon: "autorenew"
                title: "Connect automatically"
                description: "Whenever you're online."
                Switch {
                    checked: vpn.modelData.autoconnect === true
                    onToggled: VpnService.set(vpn.uuid, "autoconnect", checked ? "no" : "yes")
                }
            }
            SettingsRow {
                visible: vpn.modelData.editable === true
                icon: "history_toggle_off"
                title: "Compatibility with older servers"
                description: "Allows older TLS versions and weaker certificates. Turn on only if connecting fails with a handshake or certificate error."
                Switch {
                    checked: vpn.modelData.compat === true
                    onToggled: VpnService.set(vpn.uuid, "compat", checked ? "no" : "yes")
                }
            }

            Repeater {
                model: vpn.modelData.editable ? [
                    { key: "ca", title: "CA certificate", icon: "verified_user" },
                    { key: "cert", title: "Your certificate", icon: "workspace_premium" },
                    { key: "key", title: "Private key", icon: "key" }
                ].filter(c => c.key === "ca" || (vpn.modelData[c.key] ?? "") !== "" || vpn.modelData.connectionType.includes("tls")) : []
                SettingsRow {
                    required property var modelData
                    icon: modelData.icon
                    title: modelData.title
                    description: root.fileName(vpn.modelData[modelData.key])
                    Pill {
                        text: "Replace…"
                        implicitHeight: 32
                        onClicked: VpnService.pickCert(vpn.uuid, modelData.key)
                    }
                }
            }

            SettingsRow {
                icon: "more_horiz"
                title: "More"
                RowLayout {
                    spacing: 8
                    Pill {
                        text: vpn.logOpen ? "Hide log" : "Show log"
                        implicitHeight: 32
                        onClicked: {
                            vpn.logOpen = !vpn.logOpen;
                            if (vpn.logOpen)
                                VpnService.showLog(vpn.uuid);
                        }
                    }
                    Pill {
                        text: "All settings…"
                        tip: "NetworkManager's full editor"
                        implicitHeight: 32
                        onClicked: VpnService.editAll(vpn.uuid)
                    }
                    Pill {
                        text: vpn.confirmRemove ? "Remove for good?" : "Remove"
                        active: vpn.confirmRemove
                        implicitHeight: 32
                        onClicked: {
                            if (vpn.confirmRemove)
                                VpnService.remove(vpn.uuid);
                            else
                                vpn.confirmRemove = true;
                        }
                    }
                }
            }

            Rectangle {
                visible: vpn.logOpen
                Layout.fillWidth: true
                Layout.margins: 12
                implicitHeight: Math.min(320, logText.implicitHeight + 24)
                radius: Theme.round(12, width, height)
                color: Qt.alpha(Theme.base, 0.6)
                clip: true
                Flickable {
                    anchors { fill: parent; margins: 12 }
                    contentHeight: logText.implicitHeight
                    contentY: Math.max(0, contentHeight - height)
                    boundsBehavior: Flickable.StopAtBounds
                    Text {
                        id: logText
                        width: parent.width
                        text: VpnService.logFor === vpn.uuid && VpnService.logLines.length ? VpnService.logLines.join("\n") : "No log from the last two days."
                        color: Theme.subtext
                        font.family: Settings.appearance.monoFont
                        font.pixelSize: Theme.fontSize - 3
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }
}
