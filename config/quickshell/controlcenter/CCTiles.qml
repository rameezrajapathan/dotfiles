import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.services

GridLayout {
    id: root
    property var cc
    property bool small: false

    columns: small ? 3 : 2
    rowSpacing: 8
    columnSpacing: 8

    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.source] }

    readonly property var profileNames: ({
        [PowerProfile.PowerSaver]: "Power saver",
        [PowerProfile.Balanced]: "Balanced",
        [PowerProfile.Performance]: "Performance"
    })
    readonly property var profileIcons: ({
        [PowerProfile.PowerSaver]: "energy_savings_leaf",
        [PowerProfile.Balanced]: "balance",
        [PowerProfile.Performance]: "speed"
    })
    readonly property var activeVpn: VpnService.connections.find(c => c.active) ?? null

    readonly property var shownTiles: Settings.controlCenter.tiles.filter(id => {
        switch (id) {
        case "bluetooth": return StatusInfo.btAdapter !== null;
        case "mic": return root.source !== null;
        }
        return CCStyles.tiles.some(t => t.id === id);
    })

    function info(id) {
        switch (id) {
        case "network": {
            const wired = StatusInfo.netDevice?.type === DeviceType.Wired;
            return {
                icon: StatusInfo.icon("network"), label: wired ? "Ethernet" : "Wi-Fi",
                detail: !wired && !Networking.wifiEnabled ? "Off" : StatusInfo.detail("network"),
                active: wired || (Networking.wifiEnabled && StatusInfo.wifi !== null), more: "network",
                short: StatusInfo.wifi?.name ?? (wired ? "Ethernet" : "Wi-Fi")
            };
        }
        case "bluetooth": {
            const on = StatusInfo.btAdapter?.enabled ?? false;
            const n = (StatusInfo.btAdapter?.devices.values ?? []).filter(d => d.connected).length;
            return {
                icon: StatusInfo.icon("bluetooth"), label: "Bluetooth",
                detail: !on ? "Off" : n > 0 ? n + " connected" : "On", active: on, more: "bluetooth"
            };
        }
        case "vpn": return {
            icon: "vpn_key", label: "VPN",
            detail: root.activeVpn?.name ?? (VpnService.connections.length ? "Off" : "None set up"),
            active: root.activeVpn !== null, more: "network"
        };
        case "dnd": return {
            icon: NotificationService.dnd ? "do_not_disturb_on" : "do_not_disturb_off", label: "Do Not Disturb",
            detail: NotificationService.dnd ? "Urgent only" : NotificationService.scheduledQuiet ? "Quiet hours" : "Off",
            active: NotificationService.dnd, more: "notifications", short: "Do not disturb", compact: "DND"
        };
        case "night": return {
            icon: "nightlight", label: "Night light",
            detail: Toggles.nightLight ? Toggles.nightTemperature + " K" : Settings.display.nightSchedule !== "off" ? "Scheduled" : "Off",
            active: Toggles.nightLight, more: "display"
        };
        case "profile": return {
            icon: root.profileIcons[PowerProfiles.profile] ?? "bolt", label: root.profileNames[PowerProfiles.profile] ?? "Power",
            detail: "Power profile", active: PowerProfiles.profile !== PowerProfile.Balanced, short: "",
            more: StatusInfo.battery.isLaptopBattery ? "battery" : ""
        };
        case "awake": return {
            icon: "coffee", label: "Keep awake", detail: Toggles.keepAwake ? "No lock or sleep" : "Off",
            active: Toggles.keepAwake, more: ""
        };
        case "game": return {
            icon: "sports_esports", label: "Game mode", detail: Toggles.gameMode ? "No effects" : "Off",
            active: Toggles.gameMode, more: ""
        };
        case "mic": {
            const muted = root.source?.audio?.muted ?? true;
            return {
                icon: muted ? "mic_off" : "mic", label: "Microphone", compact: "Mic", detail: muted ? "Muted" : "On",
                active: !muted, more: "audio"
            };
        }
        case "record": return {
            icon: Recorder.active ? "stop_circle" : "screen_record", label: Recorder.active ? "Stop" : "Record",
            detail: Recorder.active ? Recorder.elapsedText : "A region", active: Recorder.active, more: "capture"
        };
        case "picker": return {
            icon: "colorize", label: "Color picker", detail: "Copies hex", active: false, more: ""
        };
        }
        return { icon: "help", label: id, detail: "", active: false, more: "" };
    }

    function act(id) {
        switch (id) {
        case "network":
            Networking.wifiEnabled = !Networking.wifiEnabled;
            break;
        case "bluetooth":
            if (StatusInfo.btAdapter)
                StatusInfo.btAdapter.enabled = !StatusInfo.btAdapter.enabled;
            break;
        case "vpn":
            if (activeVpn)
                VpnService.toggle(activeVpn.name);
            else if (VpnService.connections.length === 1)
                VpnService.toggle(VpnService.connections[0].name);
            else
                cc.openDetail("network");
            break;
        case "dnd":
            NotificationService.dnd = !NotificationService.dnd;
            break;
        case "night":
            Toggles.nightLight = !Toggles.nightLight;
            break;
        case "profile": {
            const order = [PowerProfile.PowerSaver, PowerProfile.Balanced]
                .concat(PowerProfiles.hasPerformanceProfile ? [PowerProfile.Performance] : []);
            PowerProfiles.profile = order[(order.indexOf(PowerProfiles.profile) + 1) % order.length];
            break;
        }
        case "awake":
            Toggles.keepAwake = !Toggles.keepAwake;
            break;
        case "game":
            Toggles.setGameMode(!Toggles.gameMode);
            break;
        case "mic":
            if (source?.audio)
                source.audio.muted = !source.audio.muted;
            break;
        case "record":
            if (Recorder.active) {
                Recorder.stop();
            } else {
                cc.close();
                Recorder.record("region");
            }
            break;
        case "picker":
            cc.close();
            Toggles.pickColor();
            break;
        }
    }

    Repeater {
        model: root.shownTiles

        CCTile {
            required property string modelData
            readonly property var tileInfo: root.info(modelData)

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            small: root.small
            icon: tileInfo.icon
            label: tileInfo.label
            shortLabel: tileInfo.short ?? ""
            compactLabel: tileInfo.compact ?? ""
            detail: tileInfo.detail
            active: tileInfo.active
            hasMore: tileInfo.more !== ""
            onClicked: root.act(modelData)
            onMore: root.cc.openDetail(tileInfo.more)
        }
    }
}
