pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/screenshot.sh"

    function screenshot(what) {
        run(what + " save");
    }

    function annotate() {
        run("region edit");
    }
    function copyText() {
        run("region text");
    }

    function run(args) {
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; exec " + script + " " + args]);
    }
}
