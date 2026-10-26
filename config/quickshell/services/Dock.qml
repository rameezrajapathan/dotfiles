pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property JsonObject cfg: Settings.dock
    readonly property bool enabled: cfg.enabled
    readonly property var edges: ["bottom", "left", "right"]
    readonly property string edge: {
        const want = edges.includes(cfg.position) ? cfg.position : "bottom";
        return want !== Theme.barPosition ? want : edges.find(e => e !== Theme.barPosition);
    }
    readonly property bool vertical: edge !== "bottom"
    readonly property var modes: ["always", "autohide", "intellihide"]
    readonly property string mode: modes.includes(cfg.mode) ? cfg.mode : "always"
    readonly property var indicators: ["dot", "line", "ring", "pill", "none"]
    readonly property string indicator: indicators.includes(cfg.indicator) ? cfg.indicator : "dot"
    readonly property color indicatorColor: cfg.indicatorColor ? cfg.indicatorColor : Glass.neutral ? Theme.text : Theme.accent
    readonly property int iconSize: Math.max(24, Math.min(96, cfg.iconSize))
    readonly property real magnifyScale: cfg.magnify ? Math.max(1.1, Math.min(2.5, cfg.magnifyScale)) : 1
    readonly property int pad: Math.max(8, Math.round(iconSize * 0.2))
    readonly property int spacing: Math.max(4, Math.round(iconSize * 0.14))
    readonly property int gap: 6
    readonly property int depth: iconSize + 2 * pad

    readonly property var glassOptions: ["system", "frosted", "clear", "solid"]
    readonly property var glass: {
        const p = cfg.glass;
        if (!Glass.active || !glassOptions.includes(p) || p === "system")
            return { tint: Glass.tint, rim: Glass.rim, refraction: Glass.refraction };
        if (p === "solid")
            return { tint: Glass.forMode(0.92), rim: Glass.rim * 0.5, refraction: 0 };
        const v = Glass.presets[p] ?? {};
        return { tint: Glass.forMode(v.tint ?? Glass.tint), rim: v.rim ?? Glass.rim, refraction: v.refraction ?? Glass.refraction };
    }

    property var roles: ({})
    readonly property var roleBinds: ({
        browser: "Open web browser",
        files: "Open file manager",
        editor: "Open text editor",
        terminal: "Open terminal"
    })
    readonly property var defaultPins: ["files", "browser", "terminal", "editor"]
        .map(r => Object.keys(roles).find(id => roles[id] === r))
        .filter(Boolean)
    readonly property var pinned: (cfg.pinned ?? defaultPins).filter(id => typeof id === "string" && id)

    readonly property string mainScreen: Quickshell.screens[0]?.name ?? ""

    function onScreen(name) {
        return cfg.screens !== "main" || !mainScreen || name === mainScreen;
    }

    function appId(t) {
        return t?.wayland?.appId ?? t?.lastIpcObject?.class ?? "";
    }

    function selector(t) {
        return "address:0x" + t.address.replace(/^0x/, "");
    }

    function isSpecial(t) {
        return (t?.workspace?.name ?? "").startsWith("special:");
    }

    function specialName(t) {
        return isSpecial(t) ? t.workspace.name.slice(8) : "";
    }

    function entryForWindow(t) {
        const id = appId(t);
        if (!id)
            return null;
        if (id === "org.quickshell")
            return DesktopEntries.byId("pikadots-settings");
        return DesktopEntries.heuristicLookup(id);
    }

    function entry(key) {
        return groups.map[key]?.entry ?? (key.startsWith("window:") ? null : DesktopEntries.byId(key));
    }

    readonly property var windows: Hyprland.toplevels.values
        .filter(t => t.workspace && appId(t) && (cfg.showSpecial || !isSpecial(t)))

    readonly property var groups: {
        DesktopEntries.applications.values.length;
        const map = {};
        const order = [];
        for (const t of windows) {
            const e = entryForWindow(t);
            const key = e ? e.id : "window:" + appId(t).toLowerCase();
            if (!map[key]) {
                map[key] = { key: key, entry: e, appId: appId(t), windows: [] };
                order.push(key);
            }
            map[key].windows.push(t);
        }
        return { map: map, order: order };
    }

    readonly property var items: {
        DesktopEntries.applications.values.length;
        const out = [];
        if (cfg.launcherButton)
            out.push({ key: "launcher", kind: "launcher", pinned: false });
        let apps = 0;
        for (const id of pinned) {
            if (!groups.map[id] && !DesktopEntries.byId(id))
                continue;
            out.push({ key: id, kind: "app", pinned: true });
            apps++;
        }
        const extra = cfg.showRunning ? groups.order.filter(k => !pinned.includes(k)) : [];
        if (extra.length && apps)
            out.push({ key: "divider", kind: "divider", pinned: false });
        for (const k of extra)
            out.push({ key: k, kind: "app", pinned: false });
        return out;
    }

    function recent(list) {
        return list.slice().sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 99) - (b.lastIpcObject?.focusHistoryID ?? 99));
    }

    function dispatch(dsp) {
        Quickshell.execDetached(["hyprctl", "dispatch", dsp]);
    }

    function focusWindow(t) {
        if (!t)
            return;
        const name = specialName(t);
        if (name === "background") {
            Background.show(t);
            return;
        }
        if (name && Special.on(Hyprland.focusedMonitor?.name ?? "") !== name)
            dispatch(`hl.dsp.workspace.toggle_special("${name}")`);
        dispatch(`hl.dsp.focus({ window = "${selector(t)}" })`);
    }

    function closeWindow(t) {
        if (t)
            dispatch(`hl.dsp.window.close({ window = "${selector(t)}" })`);
    }

    function closeAll(key) {
        for (const t of groups.map[key]?.windows ?? [])
            closeWindow(t);
    }

    function activate(key) {
        if (key === "launcher") {
            Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"]);
            return;
        }
        const list = groups.map[key]?.windows ?? [];
        if (!list.length) {
            launch(key);
            return;
        }
        const focused = list.find(t => t.activated);
        if (!focused)
            focusWindow(recent(list)[0]);
        else if (list.length > 1)
            focusWindow(list[(list.indexOf(focused) + 1) % list.length]);
    }

    property var launching: ({})

    function markLaunching(key) {
        const l = Object.assign({}, launching);
        l[key] = Date.now();
        launching = l;
        launchTimer.restart();
    }

    onGroupsChanged: {
        const keys = Object.keys(launching).filter(k => !groups.map[k]);
        if (keys.length !== Object.keys(launching).length) {
            const l = {};
            for (const k of keys)
                l[k] = launching[k];
            launching = l;
        }
    }

    Timer {
        id: launchTimer
        interval: 10000
        onTriggered: root.launching = {}
    }

    function launch(key) {
        const e = entry(key);
        if (!e)
            return;
        if (Background.reveal(e))
            return;
        if (e.runInTerminal)
            Apps.terminal(e.command);
        else
            e.execute();
        markLaunching(key);
    }

    function newWindowAction(e) {
        return (e?.actions ?? []).find(a => /new.?window/i.test(a.id) || /^new window$/i.test(a.name)) ?? null;
    }

    function newWindow(key) {
        const e = entry(key);
        if (!e)
            return;
        const a = newWindowAction(e);
        if (a)
            a.execute();
        else if (e.runInTerminal)
            Apps.terminal(e.command);
        else
            e.execute();
        if (!groups.map[key])
            markLaunching(key);
    }

    function runAction(key, action) {
        action.execute();
        if (!groups.map[key])
            markLaunching(key);
    }

    function canPin(key) {
        return key !== "launcher" && key !== "divider" && !key.startsWith("window:") && entry(key) !== null;
    }

    function isPinned(key) {
        return pinned.includes(key);
    }

    function pin(key, index) {
        if (!canPin(key))
            return;
        const list = pinned.filter(p => p !== key);
        list.splice(Math.max(0, Math.min(index ?? list.length, list.length)), 0, key);
        cfg.pinned = list;
    }

    function unpin(key) {
        cfg.pinned = pinned.filter(p => p !== key);
    }

    function movePin(from, to) {
        const list = pinned.slice();
        if (from < 0 || from >= list.length)
            return;
        const [k] = list.splice(from, 1);
        list.splice(Math.max(0, Math.min(to, list.length)), 0, k);
        cfg.pinned = list;
    }

    function keybindFor(key) {
        const role = roles[key];
        const b = role ? Keybinds.entries.find(e => e.desc === roleBinds[role]) : null;
        return b ? b.keys.join(" + ") : "";
    }

    property string holdScreen: ""
    property var places: ({})

    function setPlace(screen, place) {
        const old = places[screen];
        if (old && JSON.stringify(old) === JSON.stringify(place))
            return;
        const p = Object.assign({}, places);
        p[screen] = place;
        places = p;
    }

    function availableOn(screen) {
        return enabled && onScreen(screen) && (places[screen]?.available ?? false);
    }

    signal visibilityRequested(string how)

    function request(how) {
        if (!cfg.enabled) {
            if (how === "hide")
                return;
            cfg.enabled = true;
        }
        visibilityRequested(how);
    }

    IpcHandler {
        target: "dock"
        function toggle(): void {
            root.request("toggle");
        }
        function show(): void {
            root.request("show");
        }
        function hide(): void {
            root.request("hide");
        }
        function mode(name: string): void {
            if (root.modes.includes(name))
                root.cfg.mode = name;
        }
        function edge(name: string): void {
            if (root.edges.includes(name))
                root.cfg.position = name;
        }
        function pin(id: string): void {
            root.pin(id.replace(/\.desktop$/, ""));
        }
        function unpin(id: string): void {
            root.unpin(id.replace(/\.desktop$/, ""));
        }
    }

    Timer {
        id: refreshTimer
        interval: 80
        onTriggered: Hyprland.refreshToplevels()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.enabled && root.mode === "intellihide"
        onTriggered: Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen", "workspacev2", "activewindowv2", "activespecialv2"].includes(event.name))
                refreshTimer.restart();
        }
    }

    Process {
        id: roleProc
        command: ["sh", "-c", "printf '%s\\n' \"$(xdg-settings get default-web-browser 2>/dev/null)\" \"$(xdg-mime query default inode/directory 2>/dev/null)\" \"$(xdg-mime query default text/plain 2>/dev/null)\" \"$(grep -v '^#' \"${XDG_CONFIG_HOME:-$HOME/.config}/xdg-terminals.list\" 2>/dev/null | head -n1)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(l => l.trim().replace(/\.desktop$/, ""));
                const r = {};
                const names = ["browser", "files", "editor", "terminal"];
                names.forEach((n, i) => {
                    const id = lines[i] || (n === "terminal" ? (Quickshell.env("TERMINAL") || "kitty").replace(/^.*\//, "") : "");
                    if (id && !r[id])
                        r[id] = n;
                });
                root.roles = r;
            }
        }
    }

    Component.onCompleted: {
        roleProc.running = true;
        Hyprland.refreshToplevels();
    }
}
