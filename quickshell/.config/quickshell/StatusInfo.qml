pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick

// Network, Bluetooth, sound and battery state with an icon and short text for each, shared by
// the control center's sidebar and the bar's status icons. Keys are the control center's tabs.
Singleton {
    id: root

    readonly property var connectedDevices: Networking.devices.values.filter(d => d.connected)
    readonly property var netDevice: connectedDevices.find(d => d.type === DeviceType.Wired) ?? connectedDevices[0] ?? null
    readonly property var wifi: netDevice?.type === DeviceType.Wifi ? netDevice.networks.values.find(n => n.connected) ?? null : null
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btConnected: (btAdapter?.devices.values ?? []).some(d => d.connected)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property int batteryPercent: Math.round(battery.percentage * 100)
    readonly property bool charging: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged

    PwObjectTracker { objects: [root.sink] }

    function icon(key) {
        switch (key) {
        case "music": return Media.active?.isPlaying ? "graphic_eq" : "music_note";
        case "notifications": return NotificationService.dnd ? "notifications_off" : "notifications";
        case "network": return !netDevice ? "wifi_off" : wifi ? Theme.wifiIcon(wifi.signalStrength) : "lan";
        case "bluetooth": return !btAdapter?.enabled ? "bluetooth_disabled" : btConnected ? "bluetooth_connected" : "bluetooth";
        case "audio": {
            const v = sink?.audio?.volume ?? 0;
            return (sink?.audio?.muted ?? true) ? "volume_off" : v < 0.01 ? "volume_mute" : v < 0.5 ? "volume_down" : "volume_up";
        }
        case "display": return "monitor";
        case "drives": return "usb";
        case "battery": return charging ? "battery_android_frame_bolt"
            : batteryPercent <= 10 ? "battery_android_frame_alert"
            : batteryPercent >= 95 ? "battery_android_frame_full"
            : "battery_android_frame_" + Math.max(1, Math.min(6, Math.round(batteryPercent / 100 * 6)));
        case "system": return "monitoring";
        case "capture": return Recorder.active ? "radio_button_checked" : "screenshot_frame";
        case "github": return "commit";
        case "account": return "account_circle";
        }
        return "circle";
    }

    // Short text: network name, volume, battery percentage...
    function detail(key) {
        switch (key) {
        case "network": return wifi?.name ?? (netDevice ? "Wired" : "Offline");
        case "bluetooth": return !btAdapter?.enabled ? "Off" : btConnected ? "Connected" : "On";
        case "audio": return (sink?.audio?.muted ?? true) ? "Muted" : Math.round((sink?.audio?.volume ?? 0) * 100) + "%";
        case "battery": return batteryPercent + "%";
        case "drives": return Drives.mountedCount > 0 ? Drives.mountedCount + " open" : "";
        case "capture": return Recorder.active ? Recorder.elapsedText : "";
        }
        return "";
    }

}
