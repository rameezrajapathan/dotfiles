pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string folder: home + "/Pictures/Wallpapers"
    readonly property string configPath: home + "/.config/hypr/wallpaper.conf"
    readonly property string themeScript: home + "/.config/hypr/scripts/theme.sh"
    readonly property string path: pathFrom(conf.text())
    readonly property string url: path ? "file://" + path : ""

    function pathFrom(text) {
        const match = /^\s*path\s*=\s*(.+?)\s*$/m.exec(text ?? "");
        return match ? match[1].replace(/^~(?=\/)/, home) : "";
    }

    function apply(file) {
        Quickshell.execDetached([themeScript, file]);
    }

    function retheme() {
        Quickshell.execDetached([themeScript]);
    }

    function applyGlass() {
        Quickshell.execDetached([themeScript, "--glass"]);
    }

    function reload() {
        conf.reload();
    }

    FileView {
        id: conf
        path: root.configPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }
}
