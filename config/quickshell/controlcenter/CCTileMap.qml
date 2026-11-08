pragma Singleton

import Quickshell
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import qs.services

Singleton {
    id: root

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

    function available(key) {
        switch (key) {
        case "bluetooth": return StatusInfo.btAdapter !== null;
        case "battery": return StatusInfo.battery.isLaptopBattery;
        case "mic": return root.source !== null;
        }
        return true;
    }

    function shown(id) {
        return tiles[id] !== undefined && available(id);
    }

    function info(id) {
        return tiles[id]?.info() ?? { icon: "help", label: id, detail: "", active: false, more: "" };
    }

    function act(id, cc) {
        tiles[id]?.act(cc);
    }

    readonly property var tiles: ({
        network: {
            info: () => {
                const wired = StatusInfo.netDevice?.type === DeviceType.Wired;
                return {
                    icon: StatusInfo.icon("network"), label: wired ? "Ethernet" : "Wi-Fi",
                    detail: !wired && !Networking.wifiEnabled ? "Off" : StatusInfo.detail("network"),
                    active: wired || (Networking.wifiEnabled && StatusInfo.wifi !== null), more: "network",
                    short: StatusInfo.wifi?.name ?? (wired ? "Ethernet" : "Wi-Fi")
                };
            },
            act: cc => Networking.wifiEnabled = !Networking.wifiEnabled
        },
        bluetooth: {
            info: () => {
                const on = StatusInfo.btAdapter?.enabled ?? false;
                const n = (StatusInfo.btAdapter?.devices.values ?? []).filter(d => d.connected).length;
                return {
                    icon: StatusInfo.icon("bluetooth"), label: "Bluetooth",
                    detail: !on ? "Off" : n > 0 ? n + " connected" : "On", active: on, more: "bluetooth"
                };
            },
            act: cc => {
                if (StatusInfo.btAdapter)
                    StatusInfo.btAdapter.enabled = !StatusInfo.btAdapter.enabled;
            }
        },
        vpn: {
            info: () => ({
                icon: "vpn_key", label: "VPN",
                detail: root.activeVpn?.name ?? (VpnService.connections.length ? "Off" : "None set up"),
                active: root.activeVpn !== null, more: "network"
            }),
            act: cc => {
                if (root.activeVpn)
                    VpnService.toggle(root.activeVpn.name);
                else if (VpnService.connections.length === 1)
                    VpnService.toggle(VpnService.connections[0].name);
                else
                    cc.openDetail("network");
            }
        },
        dnd: {
            info: () => ({
                icon: NotificationService.dnd ? "do_not_disturb_on" : "do_not_disturb_off", label: "Do Not Disturb",
                detail: NotificationService.dnd ? "Urgent only" : NotificationService.scheduledQuiet ? "Quiet hours" : "Off",
                active: NotificationService.dnd, more: "notifications", short: "Do not disturb", compact: "DND"
            }),
            act: cc => NotificationService.dnd = !NotificationService.dnd
        },
        night: {
            info: () => ({
                icon: "nightlight", label: "Night light",
                detail: Toggles.nightLight ? Toggles.nightTemperature + " K" : Settings.display.nightSchedule !== "off" ? "Scheduled" : "Off",
                active: Toggles.nightLight, more: "display"
            }),
            act: cc => Toggles.nightLight = !Toggles.nightLight
        },
        profile: {
            info: () => ({
                icon: root.profileIcons[PowerProfiles.profile] ?? "bolt", label: root.profileNames[PowerProfiles.profile] ?? "Power",
                detail: "Power profile", active: PowerProfiles.profile !== PowerProfile.Balanced, short: "",
                more: root.available("battery") ? "battery" : ""
            }),
            act: cc => {
                const order = [PowerProfile.PowerSaver, PowerProfile.Balanced]
                    .concat(PowerProfiles.hasPerformanceProfile ? [PowerProfile.Performance] : []);
                PowerProfiles.profile = order[(order.indexOf(PowerProfiles.profile) + 1) % order.length];
            }
        },
        awake: {
            info: () => ({
                icon: "coffee", label: "Keep awake", detail: Toggles.keepAwake ? "No lock or sleep" : "Off",
                active: Toggles.keepAwake, more: ""
            }),
            act: cc => Toggles.keepAwake = !Toggles.keepAwake
        },
        game: {
            info: () => ({
                icon: "sports_esports", label: "Game mode", detail: Toggles.gameMode ? "No effects" : "Off",
                active: Toggles.gameMode, more: ""
            }),
            act: cc => Toggles.setGameMode(!Toggles.gameMode)
        },
        mic: {
            info: () => {
                const muted = root.source?.audio?.muted ?? true;
                return {
                    icon: muted ? "mic_off" : "mic", label: "Microphone", compact: "Mic", detail: muted ? "Muted" : "On",
                    active: !muted, more: "audio"
                };
            },
            act: cc => {
                if (root.source?.audio)
                    root.source.audio.muted = !root.source.audio.muted;
            }
        },
        record: {
            info: () => ({
                icon: Recorder.active ? "stop_circle" : "screen_record", label: Recorder.active ? "Stop" : "Record",
                detail: Recorder.active ? Recorder.elapsedText : "A region", active: Recorder.active, more: "capture"
            }),
            act: cc => {
                if (Recorder.active) {
                    Recorder.stop();
                } else {
                    cc.close();
                    Recorder.record("region");
                }
            }
        },
        picker: {
            info: () => ({
                icon: "colorize", label: "Color picker", detail: "Copies hex", active: false, more: ""
            }),
            act: cc => {
                cc.close();
                Toggles.pickColor();
            }
        }
    })
}
