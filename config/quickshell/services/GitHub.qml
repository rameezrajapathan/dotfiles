pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool signedIn: false
    property var items: []
    readonly property int unread: items.filter(n => n.unread).length

    function refresh() {
        fetcher.poll();
    }

    function open(n) {
        Quickshell.execDetached(["xdg-open", n.url]);
        markRead(n);
    }

    function markRead(n) {
        Quickshell.execDetached(["gh", "api", "-X", "PATCH", "notifications/threads/" + n.id]);
        items = items.map(i => i.id === n.id ? Object.assign({}, i, { unread: false }) : i);
    }

    function markAllRead() {
        Quickshell.execDetached(["gh", "api", "-X", "PUT", "notifications"]);
        items = items.map(i => Object.assign({}, i, { unread: false }));
    }

    function webUrl(subject, repo) {
        if (!subject.url)
            return "https://github.com/" + repo;
        return subject.url
            .replace("https://api.github.com/repos/", "https://github.com/")
            .replace(/\/pulls\/(\d+)$/, "/pull/$1");
    }

    JsonPoll {
        id: fetcher
        interval: 5 * 60 * 1000
        command: ["gh", "api", "notifications?all=false&per_page=30"]
        onLoaded: json => root.items = Array.isArray(json) ? json.map(n => ({
            id: n.id,
            title: n.subject.title,
            type: n.subject.type,
            repo: n.repository.full_name,
            reason: n.reason.replace(/_/g, " "),
            url: root.webUrl(n.subject, n.repository.full_name),
            unread: n.unread
        })) : []
        onFailed: root.items = []
        onExited: code => root.signedIn = code === 0
    }
}
