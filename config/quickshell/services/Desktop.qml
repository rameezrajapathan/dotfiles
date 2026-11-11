pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property JsonObject config: Settings.desktop
    readonly property bool enabled: config.enabled
    readonly property int cell: 120
    readonly property int gutter: 10
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/pikadots"
    readonly property string notesDir: stateDir + "/notes"
    readonly property string photoFolder: config.photos || Quickshell.env("HOME") + "/Pictures"

    property bool showing: false
    property bool editing: false
    property string catalogScreen: ""
    readonly property bool raised: enabled && (showing || editing)
    property var menu: null

    readonly property string focusedScreen: Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""

    readonly property var sizes: ({
        small: { w: 2, h: 2, label: "Small" },
        medium: { w: 4, h: 2, label: "Medium" },
        large: { w: 4, h: 4, label: "Large" }
    })
    readonly property var sizeOrder: ["small", "medium", "large"]
    readonly property int maxSpan: 4

    readonly property var kinds: [
        { id: "clock", content: "ClockWidget.qml", title: "Clock", icon: "schedule", about: "The time, on a dial or in big numbers, with your world clocks." },
        { id: "pixelclock", content: "PixelClockWidget.qml", title: "Pixel clock", icon: "grid_view", about: "Big block digits, like peaclock in a terminal.", min: { w: 2, h: 1 } },
        { id: "wordclock", content: "WordClockWidget.qml", title: "Word clock", icon: "text_fields", about: "The time spelled out in a grid of letters." },
        { id: "visualizer", content: "VisualizerWidget.qml", title: "Visualizer", icon: "graphic_eq", about: "The music as bars that dance (cava).", min: { w: 2, h: 1 } },
        { id: "media", content: "MediaWidget.qml", title: "Now playing", icon: "music_note", card: "media", about: "What's playing, with play, pause and skip." },
        { id: "weather", content: "WeatherWidget.qml", title: "Weather", icon: "partly_cloudy_day", card: "weather", about: "Now, the next hours and the coming days." },
        { id: "sun", content: "SunWidget.qml", title: "Sun & moon", icon: "wb_twilight", about: "Where the sun is between sunrise and sunset, and the moon's phase." },
        { id: "calendar", content: "CalendarWidget.qml", title: "Calendar", icon: "calendar_month", card: "calendar", about: "Today's date, the month and what's coming up." },
        { id: "meeting", content: "MeetingWidget.qml", title: "Next meeting", icon: "event", about: "Your next meeting with a join button, or the day's list." },
        { id: "focus", content: "FocusWidget.qml", title: "Focus timer", icon: "timer", about: "A pomodoro: 25 minutes of focus, then a break." },
        { id: "notes", content: "NotesWidget.qml", title: "Notes", icon: "sticky_note_2", about: "A note that saves as you type." },
        { id: "todo", content: "TodoWidget.qml", title: "To-do", icon: "checklist", about: "A short list to tick off." },
        { id: "system", content: "SystemWidget.qml", title: "System", icon: "memory", card: "system", about: "Processor, memory, disk and battery." },
        { id: "fetch", content: "FetchWidget.qml", title: "System info", icon: "terminal", about: "Your distro, kernel, uptime and packages, fetch style." },
        { id: "photos", content: "PhotoWidget.qml", title: "Photo frame", icon: "photo_library", about: "A slideshow of a folder of pictures." },
        { id: "github", content: "GitHubWidget.qml", title: "GitHub", icon: "code", about: "Unread GitHub notifications." },
        { id: "shortcuts", content: "ShortcutsWidget.qml", title: "Shortcuts", icon: "apps", about: "Apps, folders, files and websites a click away, each website in the browser and profile you choose.", min: { w: 1, h: 1 }, editsInPlace: true }
    ]

    readonly property var starter: [
        { kind: "pixelclock", size: "medium" },
        { kind: "weather", size: "small" },
        { kind: "sun", size: "small" },
        { kind: "calendar", size: "medium" },
        { kind: "media", size: "medium" }
    ]

    function kind(id) {
        return kinds.find(k => k.id === id) ?? null;
    }

    function minOf(kindId) {
        return kind(kindId)?.min ?? { w: 2, h: 2 };
    }

    function span(size) {
        return sizes[size] ?? sizes.small;
    }

    function dims(entry) {
        const m = minOf(entry.kind);
        const base = entry.w && entry.h ? { w: entry.w, h: entry.h } : span(entry.size);
        return {
            w: Math.max(m.w, Math.min(maxSpan, base.w)),
            h: Math.max(m.h, Math.min(maxSpan, base.h))
        };
    }

    function classOf(w, h) {
        return w >= 3 && h >= 4 ? "large" : w >= 3 && h >= 2 ? "medium" : "small";
    }

    function pixels(w, h) {
        return { w: w * cell - 2 * gutter, h: h * cell - 2 * gutter };
    }

    function screenByName(name) {
        return Quickshell.screens.find(s => s.name === name) ?? null;
    }

    function area(name) {
        const s = screenByName(name);
        if (!s)
            return { x: 0, y: 0, cols: 0, rows: 0 };
        const inset = { top: 16, bottom: 16, left: 16, right: 16 };
        inset[Theme.barPosition] += Theme.barHeight + 8;
        if (Dock.enabled && Dock.onScreen(name) && Dock.mode === "always")
            inset[Dock.edge] += Dock.edgeMargin + Dock.depth + 8;
        const w = s.width - inset.left - inset.right;
        const h = s.height - inset.top - inset.bottom;
        let cols = Math.max(0, Math.floor(w / cell));
        let rows = Math.max(0, Math.floor(h / cell));
        cols -= cols % 2;
        rows -= rows % 2;
        return {
            x: inset.left + Math.floor((w - cols * cell) / 2),
            y: inset.top + Math.floor((h - rows * cell) / 2),
            cols: cols,
            rows: rows
        };
    }

    function layout(name) {
        const all = config.layouts ?? {};
        const list = all[name];
        return list && typeof list.length === "number" ? Array.from(list).filter(e => e && kind(e.kind)) : [];
    }

    function save(name, list) {
        const all = Object.assign({}, config.layouts ?? {});
        all[name] = list.map(e => {
            const d = dims(e);
            return { id: e.id, kind: e.kind, w: d.w, h: d.h, col: e.col, row: e.row };
        });
        config.layouts = all;
    }

    function clamp(entry, a) {
        if (!a)
            return { col: entry.col ?? 0, row: entry.row ?? 0 };
        const d = dims(entry);
        return {
            col: Math.max(0, Math.min(entry.col, a.cols - d.w)),
            row: Math.max(0, Math.min(entry.row, a.rows - d.h))
        };
    }

    function fits(list, id, col, row, w, h, a) {
        if (!a || col < 0 || row < 0 || col + w > a.cols || row + h > a.rows)
            return false;
        return list.every(e => {
            if (e.id === id)
                return true;
            const o = dims(e);
            const p = clamp(e, a);
            return col >= p.col + o.w || col + w <= p.col || row >= p.row + o.h || row + h <= p.row;
        });
    }

    function freeSpot(list, w, h, a) {
        for (let col = a.cols - w; col >= 0; col--)
            for (let row = 0; row + h <= a.rows; row++)
                if (fits(list, "", col, row, w, h, a))
                    return { col: col, row: row };
        return null;
    }

    function newId() {
        return Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36);
    }

    function add(name, kindId, size) {
        if (!kind(kindId))
            return false;
        const d = dims({ kind: kindId, size: size });
        const list = layout(name);
        const spot = freeSpot(list, d.w, d.h, area(name));
        if (!spot)
            return false;
        list.push({ id: newId(), kind: kindId, w: d.w, h: d.h, col: spot.col, row: spot.row });
        save(name, list);
        return true;
    }

    function move(name, id, col, row) {
        const list = layout(name);
        const e = list.find(x => x.id === id);
        if (!e)
            return false;
        const d = dims(e);
        if (!fits(list, id, col, row, d.w, d.h, area(name)))
            return false;
        save(name, list.map(x => x.id === id ? Object.assign({}, x, { col: col, row: row }) : x));
        return true;
    }

    function resize(name, id, w, h) {
        const list = layout(name);
        const e = list.find(x => x.id === id);
        if (!e)
            return false;
        const a = area(name);
        const p = clamp(e, a);
        const d = dims({ kind: e.kind, w: w, h: h });
        if (!fits(list, id, p.col, p.row, d.w, d.h, a))
            return false;
        save(name, list.map(x => x.id === id ? Object.assign({}, x, { w: d.w, h: d.h, col: p.col, row: p.row }) : x));
        return true;
    }

    function remove(name, id) {
        save(name, layout(name).filter(x => x.id !== id));
        Quickshell.execDetached(["rm", "-f", notesDir + "/" + id + ".md"]);
        Shortcuts.forget(id);
    }

    function addStarter(name) {
        let n = 0;
        for (const s of starter)
            if (!layout(name).some(e => e.kind === s.kind) && add(name, s.kind, s.size))
                n++;
        return n;
    }

    function edit(on) {
        editing = on;
        if (!on)
            catalogScreen = "";
        menu = null;
        Shortcuts.menu = null;
    }

    function openCatalog(name) {
        editing = true;
        catalogScreen = name || focusedScreen;
        menu = null;
    }

    function openMenu(name, x, y) {
        menu = { screen: name, x: x, y: y };
    }

    function dismiss() {
        if (Shortcuts.close())
            return;
        if (menu)
            menu = null;
        else if (catalogScreen)
            catalogScreen = "";
        else if (editing)
            edit(false);
        else
            showing = false;
    }

    onEnabledChanged: if (!enabled) {
        showing = false;
        edit(false);
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", notesDir])

    JsonPoll {
        id: loader
        onLoaded: json => {
            if (Array.isArray(json))
                root.save(root.focusedScreen, json.filter(e => e && root.kind(e.kind)));
        }
        onFailed: error => console.warn("desktop load: " + error)
    }

    IpcHandler {
        target: "desktop"
        function toggle(): void {
            root.showing = !root.showing;
            if (!root.showing)
                root.edit(false);
        }
        function edit(): void {
            root.edit(!root.editing);
        }
        function menu(): void {
            if (root.menu) {
                root.menu = null;
                return;
            }
            const s = root.screenByName(root.focusedScreen);
            root.openMenu(root.focusedScreen, (s?.width ?? 400) / 2 - 155, (s?.height ?? 400) / 2 - 150);
        }
        function add(): void {
            root.openCatalog("");
        }
        function place(kind: string, size: string): bool {
            return root.add(root.focusedScreen, kind, size);
        }
        function starter(): int {
            return root.addStarter(root.focusedScreen);
        }
        function load(path: string): void {
            loader.command = ["cat", path];
            loader.running = true;
        }
        function dump(): string {
            return JSON.stringify(root.layout(root.focusedScreen));
        }
        function clear(): void {
            root.save(root.focusedScreen, []);
        }
    }
}
