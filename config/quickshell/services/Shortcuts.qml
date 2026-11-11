pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string path: Desktop.stateDir + "/shortcuts.json"
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/browsers.py"
    property var data: ({})
    property var browsers: []
    property string defaultBrowser: ""
    property bool browsersLoaded: false
    property var favicons: ({})
    property var fetching: []
    property var menu: null
    property var sheet: null
    property bool picking: false

    function listOf(widgetId) {
        const items = data[widgetId]?.items;
        return Array.isArray(items) ? items.filter(i => i && i.id) : [];
    }

    function titleOf(widgetId) {
        return data[widgetId]?.title ?? "";
    }

    function itemOf(widgetId, itemId) {
        return listOf(widgetId).find(i => i.id === itemId) ?? null;
    }

    function write(widgetId, entry) {
        const d = Object.assign({}, data);
        if (entry)
            d[widgetId] = entry;
        else
            delete d[widgetId];
        data = d;
        file.setText(JSON.stringify(d, null, 2) + "\n");
    }

    function setTitle(widgetId, title) {
        write(widgetId, { title: title.trim(), items: listOf(widgetId) });
    }

    function save(widgetId, item) {
        const list = listOf(widgetId);
        const clean = {
            id: item.id || Desktop.newId(),
            type: item.type,
            target: item.target ?? "",
            browser: item.type === "web" ? item.browser ?? "" : "",
            profile: item.type === "web" && item.browser ? item.profile ?? "" : "",
            label: (item.label ?? "").trim(),
            icon: (item.icon ?? "").trim(),
            folder: item.folder === true
        };
        const at = list.findIndex(i => i.id === clean.id);
        if (at >= 0)
            list[at] = clean;
        else
            list.push(clean);
        write(widgetId, { title: titleOf(widgetId), items: list });
        if (clean.type === "local")
            checkFolder(widgetId, clean.id, clean.target);
        return clean.id;
    }

    function remove(widgetId, itemId) {
        write(widgetId, { title: titleOf(widgetId), items: listOf(widgetId).filter(i => i.id !== itemId) });
    }

    function forget(widgetId) {
        if (data[widgetId])
            write(widgetId, null);
    }

    function expand(p) {
        return p.startsWith("~") ? Quickshell.env("HOME") + p.slice(1) : p;
    }

    function classify(address) {
        const a = address.trim();
        if (a === "")
            return { type: "", target: "" };
        if (a.startsWith("file://"))
            return { type: "local", target: decodeURIComponent(a.slice(7)) };
        if (a.startsWith("/") || a.startsWith("~"))
            return { type: "local", target: a };
        if (/^https?:\/\//i.test(a))
            return { type: "web", target: a };
        if (/^[a-z][a-z0-9+.-]*:/i.test(a) && !/^[^:\/\s]+\.[^:\/\s]+:\d+/.test(a))
            return { type: "uri", target: a };
        if (/^[^\s\/]+\.[^\s\/]+/.test(a) || /^localhost(:\d+)?(\/|$)/.test(a))
            return { type: "web", target: "https://" + a };
        return { type: "", target: a };
    }

    function hostOf(url) {
        const m = /^[a-z][a-z0-9+.-]*:\/\/([^\/?#:]+)/i.exec(url ?? "");
        return m ? m[1].toLowerCase() : "";
    }

    function baseName(p) {
        const parts = p.replace(/\/+$/, "").split("/");
        return parts[parts.length - 1] || p;
    }

    function entryOf(item) {
        return item?.type === "app" ? DesktopEntries.byId(item.target.replace(/\.desktop$/, "")) ?? null : null;
    }

    function autoLabel(item) {
        if (!item)
            return "";
        switch (item.type) {
        case "app":
            return entryOf(item)?.name ?? item.target.replace(/\.desktop$/, "");
        case "web":
            return hostOf(item.target).replace(/^www\./, "") || item.target;
        case "local":
            return expand(item.target) === Quickshell.env("HOME") ? "Home" : baseName(item.target);
        default:
            return item.target.replace(/^[a-z][a-z0-9+.-]*:(\/\/)?/i, "") || item.target;
        }
    }

    function labelOf(item) {
        return item?.label || autoLabel(item);
    }

    function browserOf(id) {
        return browsers.find(b => b.id === id) ?? null;
    }

    function profileOf(browserId, profileId) {
        return browserOf(browserId)?.profiles?.find(p => p.id === profileId) ?? null;
    }

    function nameKey(browserId, profileId) {
        return browserId + "|" + profileId;
    }

    function profileName(browserId, profile) {
        if (!profile)
            return "";
        return (Settings.desktop.profileNames ?? {})[nameKey(browserId, profile.id)] || profile.name;
    }

    function renameProfile(browserId, profileId, name) {
        const all = Object.assign({}, Settings.desktop.profileNames ?? {});
        const n = name.trim();
        if (n)
            all[nameKey(browserId, profileId)] = n;
        else
            delete all[nameKey(browserId, profileId)];
        Settings.desktop.profileNames = all;
    }

    function hashHue(text) {
        let h = 0;
        for (let i = 0; i < text.length; i++)
            h = (h * 31 + text.charCodeAt(i)) >>> 0;
        return (h % 360) / 360;
    }

    function profileColor(browserId, profile) {
        if (!profile)
            return "transparent";
        if (profile.color) {
            const c = Qt.color(profile.color);
            return c.hslLightness < 0.45 ? Qt.hsla(c.hslHue < 0 ? 0 : c.hslHue, Math.max(0.35, c.hslSaturation), 0.6, 1) : c;
        }
        return Qt.hsla(hashHue(browserId + profile.id), 0.55, 0.6, 1);
    }

    function problem(item) {
        if (!item)
            return "";
        if (item.type === "app")
            return entryOf(item) ? "" : "This app isn't installed any more.";
        if (item.type !== "web" || !item.browser || !browsersLoaded)
            return "";
        const b = browserOf(item.browser);
        if (!b)
            return "This browser isn't installed any more. It opens in your default browser.";
        if (item.profile && !b.profiles.some(p => p.id === item.profile))
            return "This profile is gone. It opens in " + b.name + "'s usual profile.";
        return "";
    }

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Shortcuts", "-i", "dialog-warning", title, body]);
    }

    function open(item, browserId, profileId) {
        if (!item)
            return;
        switch (item.type) {
        case "app": {
            const e = entryOf(item);
            if (!e) {
                notify("App not found", labelOf(item) + " isn't installed any more.");
                return;
            }
            LauncherApps.launch(e);
            return;
        }
        case "web":
            Quickshell.execDetached(["python3", "-I", script, "open",
                browserId ?? item.browser ?? "", (browserId !== undefined ? profileId : item.profile) ?? "", item.target]);
            return;
        default:
            Quickshell.execDetached([Apps.script, "open", item.type === "local" ? expand(item.target) : item.target]);
        }
    }

    function favicon(url) {
        const host = hostOf(url);
        if (!host)
            return "";
        const known = favicons[host];
        if (known !== undefined)
            return known;
        Qt.callLater(requestFavicon, host);
        return "";
    }

    function requestFavicon(host) {
        if (favicons[host] !== undefined || fetching.includes(host))
            return;
        fetching = fetching.concat([host]);
        if (!iconFetch.running)
            nextFavicon();
    }

    function nextFavicon() {
        if (fetching.length === 0)
            return;
        iconFetch.host = fetching[0];
        iconFetch.command = ["python3", "-I", script, "favicon", "https://" + fetching[0]];
        iconFetch.running = true;
    }

    function refreshBrowsers() {
        browserList.poll();
    }

    function checkFolder(widgetId, itemId, target) {
        folderCheck.pending = folderCheck.pending.concat([{ widget: widgetId, item: itemId, target: target }]);
        if (!folderCheck.running)
            folderCheck.next();
    }

    function openMenu(screenName, widgetId, itemId, x, y) {
        sheet = null;
        menu = { screen: screenName, widget: widgetId, item: itemId, x: x, y: y };
        refreshBrowsers();
    }

    function edit(screenName, widgetId, itemId) {
        menu = null;
        sheet = { screen: screenName || Desktop.focusedScreen, widget: widgetId, item: itemId ?? "" };
        refreshBrowsers();
    }

    function close() {
        if (menu)
            menu = null;
        else if (sheet)
            sheet = null;
        else
            return false;
        return true;
    }

    JsonPoll {
        id: browserList
        command: ["python3", "-I", root.script, "list"]
        onLoaded: json => {
            root.browsers = Array.from(json?.browsers ?? []).map(b => Object.assign({}, b, { profiles: Array.from(b.profiles ?? []) }));
            root.defaultBrowser = json.default ?? "";
            root.browsersLoaded = true;
        }
        onFailed: error => console.warn("shortcuts browsers: " + error)
    }

    Process {
        id: iconFetch
        property string host: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const f = Object.assign({}, root.favicons);
                const p = text.trim();
                f[iconFetch.host] = p ? "file://" + p : "";
                root.favicons = f;
            }
        }
        onExited: {
            root.fetching = root.fetching.filter(h => h !== host);
            Qt.callLater(root.nextFavicon);
        }
    }

    Process {
        id: folderCheck
        property var pending: []
        property var current: null
        function next() {
            if (pending.length === 0)
                return;
            current = pending[0];
            pending = pending.slice(1);
            command = ["test", "-d", root.expand(current.target)];
            running = true;
        }
        onExited: code => {
            const c = current;
            const item = c ? root.itemOf(c.widget, c.item) : null;
            if (item && item.target === c.target && item.folder !== (code === 0)) {
                const list = root.listOf(c.widget).map(i => i.id === c.item ? Object.assign({}, i, { folder: code === 0 }) : i);
                root.write(c.widget, { title: root.titleOf(c.widget), items: list });
            }
            Qt.callLater(next);
        }
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.data = d && typeof d === "object" && !Array.isArray(d) ? d : {};
            } catch (e) {
                console.warn("shortcuts: " + e);
            }
        }
    }

    Component.onCompleted: browserList.poll()
}
