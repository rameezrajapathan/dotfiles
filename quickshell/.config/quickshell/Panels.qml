pragma Singleton

import Quickshell
import QtQuick

// Only one panel open at a time: each panel holds an Exclusive, which announces it here when it
// opens and closes it when another one does (control center, calendar, launcher, wallpaper
// picker, power menu, overview, cheatsheet). Also tracks which bars a Sheet covers.
Singleton {
    signal opened(var panel)

    // Screens whose bar pill is covered by a Sheet's copy of it (the real one hides meanwhile)
    property var covered: ({})

    function cover(screen, on) {
        const c = Object.assign({}, covered);
        c[screen] = Math.max(0, (c[screen] ?? 0) + (on ? 1 : -1));
        covered = c;
    }
}
