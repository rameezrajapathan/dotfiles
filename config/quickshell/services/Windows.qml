pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    readonly property var windows: byRecent(Hyprland.toplevels.values
        .filter(t => (t.workspace?.id ?? -1) > 0 && t.lastIpcObject?.at !== undefined))

    function refresh() {
        Hyprland.refreshToplevels();
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
    }

    function dispatch(dsp) {
        Quickshell.execDetached(["hyprctl", "dispatch", dsp]);
    }

    function selector(t) {
        return "address:0x" + t.address.replace(/^0x/, "");
    }

    function appId(t) {
        return t?.wayland?.appId ?? t?.lastIpcObject?.class ?? "";
    }

    function recency(t) {
        return t?.lastIpcObject?.focusHistoryID ?? 99;
    }

    function byRecent(list) {
        return list.slice().sort((a, b) => recency(a) - recency(b));
    }

    function specialWorkspace(name) {
        return "special:" + name;
    }

    function specialOf(workspaceName) {
        return (workspaceName ?? "").startsWith("special:") ? workspaceName.slice(8) : "";
    }

    function isSpecial(t) {
        return specialName(t) !== "";
    }

    function specialName(t) {
        return specialOf(t?.workspace?.name);
    }

    function toggleSpecial(name) {
        if (name)
            dispatch(`hl.dsp.workspace.toggle_special("${name}")`);
    }

    function focus(t) {
        if (!t)
            return;
        const name = specialName(t);
        if (name === "minimized" && t.wayland) {
            t.wayland.minimized = false;
            return;
        }
        if (name && Special.on(Hyprland.focusedMonitor?.name ?? "") !== name)
            toggleSpecial(name);
        dispatch(`hl.dsp.focus({ window = "${selector(t)}" })`);
    }

    function close(t) {
        if (t)
            dispatch(`hl.dsp.window.close({ window = "${selector(t)}" })`);
    }

    function focusWorkspace(id) {
        dispatch(`hl.dsp.focus({ workspace = "${id}" })`);
    }

    function stepWorkspace(delta) {
        focusWorkspace(delta > 0 ? "e+1" : "e-1");
    }

    function submap(name) {
        dispatch(`hl.dsp.submap("${name}")`);
    }

    function icon(t) {
        const id = appId(t);
        const name = DesktopEntries.heuristicLookup(id)?.icon ?? id;
        return Quickshell.iconPath(Quickshell.hasThemeIcon(name) ? name : "application-x-executable");
    }
}
