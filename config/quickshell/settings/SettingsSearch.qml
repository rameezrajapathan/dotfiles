import QtQuick

QtObject {
    id: root
    required property var app
    property var host: null
    property string query
    property var hits: []
    property var pendingHit: null

    readonly property var words: query.toLowerCase().split(/\s+/).filter(w => w)
    readonly property bool active: query.trim() !== ""
    readonly property var shownPages: app.pages.filter(p => app.available(p.key)
        && words.every(w => (p.title + " " + p.keywords).toLowerCase().includes(w)))

    onQueryChanged: {
        if (shownPages.length && !shownPages.some(p => p.key === app.page))
            app.page = shownPages[0].key;
        hitTimer.restart();
    }

    function collectRows(item, out) {
        for (const child of item.children) {
            if (child.objectName === "settingsRow" && child.title)
                out.push(child);
            collectRows(child, out);
        }
    }

    function findHits() {
        const out = [];
        if (words.length && host) {
            for (let i = 0; i < host.count; i++) {
                const flick = host.pageAt(i);
                if (!flick?.page || !app.available(flick.modelData.key))
                    continue;
                const rows = [];
                collectRows(flick.page, rows);
                for (const row of rows) {
                    const text = (row.title + " " + row.description).toLowerCase();
                    if (words.every(w => text.includes(w)))
                        out.push({ key: flick.modelData.key, page: flick.modelData.title, title: row.title, row: row, flick: flick });
                }
            }
        }
        hits = out.slice(0, 8);
    }

    function jump(hit) {
        app.page = hit.key;
        pendingHit = hit;
        jumpTimer.restart();
    }

    function step(delta) {
        const list = shownPages.length ? shownPages : app.pages;
        const i = list.findIndex(p => p.key === app.page);
        app.page = list[(i + delta + list.length) % list.length].key;
    }

    property Timer hitTimer: Timer {
        interval: 120
        onTriggered: root.findHits()
    }

    property Timer jumpTimer: Timer {
        interval: 60
        onTriggered: {
            const hit = root.pendingHit;
            if (!hit)
                return;
            const y = hit.row.mapToItem(hit.flick.contentItem, 0, 0).y;
            hit.flick.contentY = Math.max(0, Math.min(hit.flick.contentHeight - hit.flick.height, y - 80));
            hit.row.flash();
        }
    }
}
