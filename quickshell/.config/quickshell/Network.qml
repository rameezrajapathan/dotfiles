import Quickshell.Networking
import QtQuick

// Wired, Wi-Fi strength or offline, plus a key while a VPN is connected. Click for NetworkPanel.
Item {
    id: root
    signal clicked()

    // Prefer wired when both are up
    readonly property var connected: Networking.devices.values.filter(d => d.connected)
    readonly property var device: connected.find(d => d.type === DeviceType.Wired) ?? connected[0] ?? null
    readonly property var wifi: device?.type === DeviceType.Wifi
        ? device.networks.values.find(n => n.connected) ?? null
        : null

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Icon {
            name: !root.device ? "wifi_off"
                : root.wifi ? Theme.wifiIcon(root.wifi.signalStrength)
                : "lan"
            color: root.device ? Theme.text : Theme.overlay
        }
        // Shown while a VPN is connected
        Icon {
            visible: VpnService.anyActive
            name: "vpn_key"
            size: 17
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
