pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

// Shared by WindowSwitcher (Alt + Tab) and Overview (Super + Tab): Hyprland's windows on normal
// workspaces with their geometry, plus focusing and icons.
Singleton {
    id: root

    // Windows on regular workspaces (special ones like the background apps are left out),
    // most recently focused first
    readonly property var windows: Hyprland.toplevels.values
        .filter(t => (t.workspace?.id ?? -1) > 0 && t.lastIpcObject?.at !== undefined)
        .sort((a, b) => (a.lastIpcObject.focusHistoryID ?? 99) - (b.lastIpcObject.focusHistoryID ?? 99))

    // Fresh positions, sizes and focus order before showing anything
    function refresh() {
        Hyprland.refreshToplevels();
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
    }

    function selector(t) {
        return "address:0x" + t.address.replace(/^0x/, "");
    }

    function focus(t) {
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ window = "${selector(t)}" })`]);
    }

    function focusWorkspace(id) {
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = "${id}" })`]);
    }

    function appId(t) {
        return t.wayland?.appId ?? t.lastIpcObject?.class ?? "";
    }

    function icon(t) {
        const id = appId(t);
        const name = DesktopEntries.heuristicLookup(id)?.icon ?? id;
        return Quickshell.iconPath(Quickshell.hasThemeIcon(name) ? name : "application-x-executable");
    }
}
