pragma Singleton

import Quickshell
import QtQuick

// Screenshot helpers (hypr/scripts/screenshot.sh); the short delay lets menus close first.
Singleton {
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/screenshot.sh"

    // "region", "active" or "full"; saved to ~/Pictures/Screenshots and copied
    function screenshot(what) {
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; exec " + script + " " + what + " save"]);
    }
}
