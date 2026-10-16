pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

// Apps that Super + Q hides in special:background instead of closing (hypr/background.lua has
// the same list). Hidden there, opening them again does nothing by itself: Chrome apps don't ask
// Hyprland to show their window when launched a second time, and Hyprland would show the whole
// special workspace (every hidden app, over the screen) if they did. So the launcher and
// notification clicks bring the window to the current workspace through here instead.
Singleton {
    id: root

    readonly property var pattern: /^(org\.mozilla\.Thunderbird|thunderbird|chrome-[a-p]+-.+)$/
    readonly property string workspace: "special:background"

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

    // To the focused monitor's workspace, focused
    function show(t) {
        const ws = Hyprland.focusedMonitor?.activeWorkspace?.id;
        if (isHidden(t) && ws !== undefined)
            dispatch(`hl.dsp.window.move({ workspace = "${ws}", window = "${selector(t)}" })`);
        dispatch(`hl.dsp.focus({ window = "${selector(t)}" })`);
    }

    // The hidden window of a desktop entry (its id or StartupWMClass is the window's class)
    function hiddenFor(entry) {
        const ids = [entry?.id, entry?.startupClass].filter(Boolean).map(s => s.toLowerCase());
        return windows.find(t => isHidden(t) && ids.includes(appId(t).toLowerCase())) ?? null;
    }

    // Brings back the app's hidden window instead of starting it again; false if there's none
    function reveal(entry) {
        const t = hiddenFor(entry);
        if (!t)
            return false;
        show(t);
        return true;
    }

    // A background app's window a notification came from: by its desktop entry, or its app
    // name against the window's app name or title
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

    // After a notification click: show the app it came from. Apps that try to raise their own
    // window then (Hyprland marks it urgent instead) are caught for a moment too.
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
