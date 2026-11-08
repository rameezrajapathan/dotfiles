pragma Singleton

import Quickshell
import QtQuick

Singleton {
    signal opened(var panel)
    signal toggleRequested(string panel, string tab)

    readonly property var barPanels: ["controlcenter", "calendar", "weather"]
    property var covered: ({})
    property var covers: ({})
    property int nextKey: 0

    function ipc(target, method, args) {
        Quickshell.execDetached(["qs", "ipc", "call", target, method].concat(args ?? []));
    }

    function toggle(panel, tab) {
        if (barPanels.includes(panel))
            toggleRequested(panel, tab ?? "");
        else
            ipc(panel, "toggle");
    }

    function action(name) {
        if (name.startsWith("cc:"))
            toggle("controlcenter", name.slice(3));
        else
            toggle(name);
    }

    function newKey() {
        return ++nextKey;
    }

    function cover(key, screen, on) {
        const c = Object.assign({}, covers);
        if (on && screen)
            c[key] = screen;
        else
            delete c[key];
        covers = c;
        const n = {};
        for (const k in c)
            n[c[k]] = (n[c[k]] ?? 0) + 1;
        covered = n;
    }
}
