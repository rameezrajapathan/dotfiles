pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// USB drives, SD cards and attached disk images, from lsblk; refreshed whenever udisks reports a
// change (`udisksctl monitor`). Mounting and ejecting go through hypr/scripts/drives.sh, which also
// sends the notifications. A drive plugged in while the shell runs is opened on its own when
// Settings > Drives "Open when plugged in" is on, or offered in a notification otherwise.
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/drives.sh"
    // One entry per filesystem: { path, disk, name, size, used, fstype, mountpoint, locked, kind, icon }
    property var volumes: []
    readonly property int mountedCount: volumes.filter(v => v.mountpoint !== "").length
    property bool loaded: false
    // Devices seen so far, so only new ones are opened on their own
    property var known: ({})

    function refresh() {
        refreshTimer.restart();
    }

    function run(args) {
        Quickshell.execDetached([script].concat(args));
        refreshTimer.restart();
    }

    function mount(volume) {
        if (volume.locked)
            run(["unlock", volume.path, "--open"]);
        else
            run(["mount", volume.path, "--open"]);
    }

    function eject(volume) {
        run(["eject", volume.disk]);
    }

    // Open the drive's folder, mounting it first if needed
    function open(volume) {
        if (volume.mountpoint !== "")
            Apps.files(volume.mountpoint);
        else
            mount(volume);
    }

    function formatSize(bytes) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (bytes >= 1000 && i < units.length - 1) {
            bytes /= 1000;
            i++;
        }
        return (bytes >= 100 || i === 0 ? Math.round(bytes) : bytes.toFixed(1)) + " " + units[i];
    }

    function parse(text) {
        let devices;
        try {
            devices = JSON.parse(text).blockdevices ?? [];
        } catch (e) {
            return;
        }
        const list = [];
        for (const disk of devices) {
            // Removable or hot-plugged disks (USB, SD cards) and disk images; never the system's own
            const image = disk.type === "loop";
            if (!(disk.rm || disk.hotplug || image) || (disk.size ?? 0) === 0)
                continue;
            const kind = image ? "image" : (disk.path ?? "").includes("mmcblk") ? "sd" : disk.tran === "usb" ? "usb" : "drive";
            const model = [disk.vendor, disk.model].filter(s => s).map(s => s.trim()).join(" ");
            const add = (node, locked) => {
                const mountpoint = (node.mountpoints ?? []).find(m => m) ?? "";
                list.push({
                    path: node.path,
                    disk: disk.path,
                    name: node.label || model || formatSize(node.size) + (image ? " image" : " drive"),
                    size: node.fssize || node.size || 0,
                    used: node.fsused ?? 0,
                    fstype: node.fstype ?? "",
                    mountpoint: mountpoint,
                    locked: locked,
                    kind: kind,
                    icon: locked ? "lock" : kind === "sd" ? "sd_card" : kind === "image" ? "album" : kind === "usb" ? "usb" : "hard_drive"
                });
            };
            const walk = node => {
                const children = node.children ?? [];
                if (node.fstype === "crypto_LUKS" && children.length === 0)
                    add(node, true);
                else if (node.fstype && node.fstype !== "crypto_LUKS" && node.fstype !== "swap" && children.length === 0)
                    add(node, false);
                children.forEach(walk);
            };
            walk(disk);
        }

        // Newly plugged in: open it, or offer to (not for what was there when the shell started)
        const seen = {};
        for (const v of list) {
            seen[v.path] = true;
            if (loaded && !known[v.path] && v.mountpoint === "" && !v.locked && v.kind !== "image") {
                if (Settings.drives.automount)
                    Quickshell.execDetached([script, "mount", v.path, "--notify"].concat(Settings.drives.openFiles ? ["--open"] : []));
                else
                    Quickshell.execDetached([script, "offer", v.path]);
            }
        }
        known = seen;
        loaded = true;
        volumes = list;
    }

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: {
            if (lsblk.running)
                restart();
            else
                lsblk.running = true;
        }
    }

    Process {
        id: lsblk
        command: ["lsblk", "-J", "-b", "-p", "-o", "PATH,LABEL,SIZE,FSTYPE,MOUNTPOINTS,RM,HOTPLUG,TRAN,VENDOR,MODEL,TYPE,FSUSED,FSSIZE"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    // Every udisks change prints a few lines; one refresh per burst
    Process {
        id: monitor
        running: true
        command: ["udisksctl", "monitor"]
        stdout: SplitParser {
            onRead: refreshTimer.restart()
        }
        onRunningChanged: {
            if (!running)
                restartMonitor.start();
        }
    }
    Timer {
        id: restartMonitor
        interval: 5000
        onTriggered: monitor.running = true
    }

    Component.onCompleted: lsblk.running = true
}
