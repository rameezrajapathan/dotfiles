pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string usageFile: stateDir + "/launcher.json"
    property var usage: ({})

    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    function search(q, category) {
        const pool = category ? apps.filter(e => e.categories.includes(category)) : apps;
        if (q === "")
            return Settings.launcher.mostUsedFirst
                ? pool.slice().sort((a, b) => (usage[b.id] ?? 0) - (usage[a.id] ?? 0) || a.name.localeCompare(b.name))
                : pool;
        const scored = [];
        for (const e of pool) {
            const s = score(e, q);
            if (s >= 0)
                scored.push({ e: e, s: s });
        }
        return scored
            .sort((a, b) => a.s - b.s || (usage[b.e.id] ?? 0) - (usage[a.e.id] ?? 0) || a.e.name.localeCompare(b.e.name))
            .map(x => x.e);
    }

    function score(e, q) {
        const name = e.name.toLowerCase();
        if (name.startsWith(q))
            return 0;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 1;
        if (name.includes(q))
            return 2;
        const extra = [e.genericName, e.comment].concat(e.keywords, e.categories).join(" ").toLowerCase();
        return extra.includes(q) ? 3 : -1;
    }

    function iconFor(e) {
        if (e.icon.startsWith("/"))
            return "file://" + e.icon;
        return Quickshell.iconPath(Quickshell.hasThemeIcon(e.icon) ? e.icon : "application-x-executable");
    }

    function launch(e) {
        const counts = Object.assign({}, usage);
        counts[e.id] = (counts[e.id] ?? 0) + 1;
        usage = counts;
        usageView.setText(JSON.stringify(counts));
        if (e.runInTerminal)
            Apps.terminal(e.command);
        else
            e.execute();
    }

    function forget() {
        usage = {};
        usageView.setText("{}");
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", stateDir])

    FileView {
        id: usageView
        path: root.usageFile
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (err) {
                root.usage = {};
            }
        }
    }
}
