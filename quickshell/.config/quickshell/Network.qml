import Quickshell.Networking
import QtQuick

Label {
    // Prefer wired when both are up
    readonly property var connected: Networking.devices.values.filter(d => d.connected)
    readonly property var device: connected.find(d => d.type === DeviceType.Wired) ?? connected[0] ?? null
    readonly property var wifi: device?.type === DeviceType.Wifi
        ? device.networks.values.find(n => n.connected) ?? null
        : null

    text: !device ? "󰤮 offline"
        : wifi ? ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(wifi.signalStrength * 5))] + " " + wifi.name
        : "󰈀 wired"
    color: device ? Theme.text : Theme.overlay
}
