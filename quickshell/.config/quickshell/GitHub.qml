pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// GitHub notifications through the gh CLI (review requests, mentions, CI failures, …), polled
// every 5 minutes. `signedIn` stays false until `gh auth login` has been run.
Singleton {
    id: root

    property bool signedIn: false
    // { id, title, repo, reason, type, url, unread }
    property var items: []
    readonly property int unread: items.filter(n => n.unread).length

    function refresh() {
        if (!fetcher.running)
            fetcher.running = true;
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

    // API URLs (api.github.com/repos/o/r/pulls/1) to web ones (github.com/o/r/pull/1)
    function webUrl(subject, repo) {
        if (!subject.url)
            return "https://github.com/" + repo;
        return subject.url
            .replace("https://api.github.com/repos/", "https://github.com/")
            .replace(/\/pulls\/(\d+)$/, "/pull/$1");
    }

    Process {
        id: fetcher
        command: ["gh", "api", "notifications?all=false&per_page=30"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.items = JSON.parse(text).map(n => ({
                        id: n.id,
                        title: n.subject.title,
                        type: n.subject.type,
                        repo: n.repository.full_name,
                        reason: n.reason.replace(/_/g, " "),
                        url: root.webUrl(n.subject, n.repository.full_name),
                        unread: n.unread
                    }));
                } catch (e) {
                    root.items = [];
                }
            }
        }
        // gh exits non-zero when not signed in
        onExited: code => root.signedIn = code === 0
    }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
