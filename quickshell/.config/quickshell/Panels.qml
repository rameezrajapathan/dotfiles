pragma Singleton

import Quickshell
import QtQuick

// Only one panel open at a time: each panel holds an Exclusive, which announces it here when it
// opens and closes it when another one does (control center, calendar, launcher, wallpaper
// picker, power menu, overview, cheatsheet). Also tracks which bars a Sheet covers.
Singleton {
    signal opened(var panel)

    // Screens whose bar pill is covered by a Sheet's copy of it (the real one hides meanwhile):
    // screen name → how many sheets cover it. Worked out from `covers` (sheet key → screen), so a
    // sheet that reports twice, or uncovers after its screen name changed, can't leave it stuck.
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
