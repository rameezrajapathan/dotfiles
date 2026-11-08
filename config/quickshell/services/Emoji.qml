pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var list: []

    function search(q) {
        const words = q.split(/\s+/).filter(w => w);
        return list.filter(e => words.every(w => e.name.includes(w)));
    }

    FileView {
        path: "/usr/share/unicode/emoji/emoji-test.txt"
        printErrors: false
        onLoaded: {
            const out = [];
            for (const line of text().split("\n")) {
                const m = line.match(/; fully-qualified\s+# (\S+) E[\d.]+ (.+)$/);
                if (m)
                    out.push({ char: m[1], name: m[2].toLowerCase() });
            }
            root.list = out;
        }
    }
}
