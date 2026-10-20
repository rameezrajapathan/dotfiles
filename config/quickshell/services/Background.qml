pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property var regexes: appList.text().split("\n").map(l => l.trim()).filter(Boolean)
    readonly property var pattern: regexes.length ? new RegExp(regexes.map(r => `(?:${r})`).join("|")) : /(?!)/
    readonly property string workspace: "special:background"

    FileView {
        id: appList
        path: Quickshell.env("HOME") + "/.config/hypr/background-apps.txt"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    function appId(t) {
        return t?.wayland?.appId ?? t?.lastIpcObject?.class ?? "";
    }

    function isHidden(t) {
        return t?.workspace?.name === workspace;
    }

    readonly property var windows: Hyprland.toplevels.values.filter(t => pattern.test(appId(t)))

    function selector(t) {
        return "address:0x" + t.address.replace(/^0x/, "");
    }

    function dispatch(dsp) {
        Quickshell.execDetached(["hyprctl", "dispatch", dsp]);
    }

    function show(t) {
        const ws = Hyprland.focusedMonitor?.activeWorkspace?.id;
        if (isHidden(t) && ws !== undefined)
            dispatch(`hl.dsp.window.move({ workspace = "${ws}", window = "${selector(t)}" })`);
        dispatch(`hl.dsp.focus({ window = "${selector(t)}" })`);
    }

    function hiddenFor(entry) {
        const ids = [entry?.id, entry?.startupClass].filter(Boolean).map(s => s.toLowerCase());
        return windows.find(t => isHidden(t) && ids.includes(appId(t).toLowerCase())) ?? null;
    }

    function reveal(entry) {
        const t = hiddenFor(entry);
        if (!t)
            return false;
        show(t);
        return true;
    }

    function windowFor(n) {
        const entry = (n.desktopEntry ?? "").toLowerCase();
        const name = (n.appName ?? "").toLowerCase();
        return windows.find(t => {
            const id = appId(t).toLowerCase();
            if (entry && (entry === id || entry === id.replace(/\.desktop$/, "")))
                return true;
            if (!name)
                return false;
            const appName = (DesktopEntries.byId(appId(t))?.name ?? "").toLowerCase();
            return appName && (appName === name || name.includes(appName) || appName.includes(name))
                || (t.title ?? "").toLowerCase().includes(name);
        }) ?? null;
    }

    property real clickedAt: 0

    function notificationClicked(n) {
        clickedAt = Date.now();
        const t = windowFor(n);
        if (t)
            show(t);
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "urgent" || Date.now() - root.clickedAt > 3000)
                return;
            const address = event.data.replace(/^0x/, "");
            const t = root.windows.find(w => w.address.replace(/^0x/, "") === address);
            if (t && root.isHidden(t))
                root.show(t);
        }
    }
}
