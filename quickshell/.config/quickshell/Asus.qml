pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// ROG laptop controls through asusctl (asusd): battery charge limit, one-time full charge and the
// GPU mode. GPU modes are firmware settings that apply after a restart:
//   Ultimate  MUX = dGPU: the NVIDIA GPU drives the screen
//   Hybrid    MUX = Optimus: Intel drives the screen, NVIDIA wakes when needed
//   Eco       Hybrid with the NVIDIA GPU switched off (only reachable from Hybrid, so the screen
//             always has a GPU)
Singleton {
    id: root

    property bool available: false
    property int chargeLimit: 100
    property int mux: 0
    property bool dgpuOff: false
    property bool pendingReboot: false
    readonly property string gpuMode: mux === 0 ? "ultimate" : dgpuOff ? "eco" : "hybrid"
    // Mode chosen in this session, waiting for a restart
    property string requestedMode: ""

    function refresh() {
        if (!reader.running)
            reader.running = true;
    }

    function setChargeLimit(percent) {
        chargeLimit = percent;
        Quickshell.execDetached(["asusctl", "battery", "limit", String(percent)]);
    }

    function chargeOnce() {
        Quickshell.execDetached(["sh", "-c", "asusctl battery oneshot && notify-send -a Battery 'Charging to 100% once' 'The limit comes back after this charge.'"]);
    }

    function setGpuMode(mode) {
        let cmd;
        if (mode === "ultimate")
            cmd = "asusctl armoury set dgpu_disable 0; asusctl armoury set gpu_mux_mode 0";
        else if (mode === "hybrid")
            cmd = "asusctl armoury set dgpu_disable 0; asusctl armoury set gpu_mux_mode 1";
        else if (mode === "eco" && mux === 1)
            cmd = "asusctl armoury set dgpu_disable 1";
        else
            return;
        requestedMode = mode;
        Quickshell.execDetached(["sh", "-c", cmd + " && notify-send -a 'GPU mode' 'Restart to switch the GPU mode' 'The new mode applies after the next restart.'"]);
        refreshTimer.restart();
    }

    // Keyboard backlight color (theme.sh sets it to the wallpaper's accent)
    function setKeyboardColor(hex) {
        Quickshell.execDetached(["asusctl", "aura", "effect", "static", "-c", hex.replace("#", "")]);
    }

    // Prints: charge limit, MUX mode, dGPU disabled, pending reboot (missing values are "-")
    Process {
        id: reader
        command: ["sh", "-c", `a=/sys/class/firmware-attributes/asus-armoury/attributes
            for f in /sys/class/power_supply/BAT0/charge_control_end_threshold \
                "$a/gpu_mux_mode/current_value" "$a/dgpu_disable/current_value" "$a/pending_reboot"; do
                cat "$f" 2>/dev/null || echo -
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().split("\n");
                root.chargeLimit = Number(v[0]) || 100;
                root.available = v[1] !== undefined && v[1] !== "-";
                root.mux = Number(v[1]) || 0;
                root.dgpuOff = v[2] === "1";
                root.pendingReboot = v[3] === "1";
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 1500
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
