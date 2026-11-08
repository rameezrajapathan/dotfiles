pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string appId
    property var callback: null

    function capture(cls, done) {
        appId = cls;
        callback = done;
        query.poll();
    }

    JsonPoll {
        id: query
        command: ["sh", "-c", "printf '{\"clients\":%s,\"monitors\":%s}' \"$(hyprctl -j clients)\" \"$(hyprctl -j monitors)\""]
        onLoaded: data => {
            const done = root.callback;
            root.callback = null;
            const c = (data.clients ?? []).filter(c => c.class === root.appId)
                .sort((a, b) => a.focusHistoryID - b.focusHistoryID)[0];
            const m = c && (data.monitors ?? []).find(m => m.id === c.monitor);
            if (!c || !m || !done)
                return;
            done({ x: c.at[0] - m.x, y: c.at[1] - m.y, width: c.size[0], height: c.size[1] });
        }
    }
}
