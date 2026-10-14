import Quickshell.Networking
import QtQuick

Label {
    id: root
    signal clicked()

    // Prefer wired when both are up
    readonly property var connected: Networking.devices.values.filter(d => d.connected)
    readonly property var device: connected.find(d => d.type === DeviceType.Wired) ?? connected[0] ?? null
    readonly property var wifi: device?.type === DeviceType.Wifi
        ? device.networks.values.find(n => n.connected) ?? null
        : null

    font.pixelSize: Theme.fontSize + 3
    text: (!device ? "󰤮"
        : wifi ? Theme.wifiIcon(wifi.signalStrength)
        : "󰈀") + vpnMark
    // Shown while a VPN is connected; set to "" to hide it.
    readonly property string vpnMark: VpnService.anyActive ? "  󰖂" : ""
    color: device ? Theme.text : Theme.overlay

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
