pragma Singleton

import Quickshell
import QtQuick
import qs.widgets

Singleton {
    signal opened(var panel)

    property var covered: ({})
    property var covers: ({})
    property int nextKey: 0

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
