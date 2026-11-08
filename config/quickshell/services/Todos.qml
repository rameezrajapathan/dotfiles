pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias items: adapter.items

    function add(text) {
        const t = text.trim();
        if (t)
            items = items.concat([{ text: t, done: false }]);
    }

    function toggle(i) {
        items = items.map((t, j) => j === i ? { text: t.text, done: !t.done } : t);
    }

    function remove(i) {
        items = items.filter((t, j) => j !== i);
    }

    function clearDone() {
        items = items.filter(t => !t.done);
    }

    FileView {
        path: Desktop.stateDir + "/todo.json"
        printErrors: false
        blockWrites: true
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property var items: []
        }
    }
}
