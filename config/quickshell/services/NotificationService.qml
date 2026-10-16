pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    property var popups: []
    property alias dnd: state.dnd
    readonly property bool scheduledQuiet: {
        const n = Settings.notifications;
        if (!n.schedule)
            return false;
        const minutes = t => {
            const [h, m] = t.split(":").map(Number);
            return h * 60 + (m || 0);
        };
        const now = clock.date.getHours() * 60 + clock.date.getMinutes();
        const from = minutes(n.from), to = minutes(n.to);
        return from <= to ? now >= from && now < to : now >= from || now < to;
    }
    readonly property bool quiet: dnd || scheduledQuiet

    PersistentProperties {
        id: state
        reloadableId: "notifications"
        property bool dnd: false
    }

    signal panelToggleRequested()
    property var times: ({})

    function hidePopup(n) {
        popups = popups.filter(p => p !== n);
    }

    function clearPopups() {
        popups = [];
    }

    function dismissAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    function activate(n) {
        const action = n.actions.find(a => a.identifier === "default");
        Background.notificationClicked(n);
        if (action)
            action.invoke();
        hidePopup(n);
    }

    function ago(n) {
        const t = times[n.id];
        if (!t)
            return "";
        const mins = Math.floor((clock.date - t) / 60000);
        return mins < 1 ? "now" : mins < 60 ? mins + "m ago" : Math.floor(mins / 60) + "h ago";
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void {
            root.panelToggleRequested();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            root.times[n.id] = new Date();
            if (!root.quiet || n.urgency === NotificationUrgency.Critical)
                root.popups = [n].concat(root.popups);
            n.closed.connect(() => root.hidePopup(n));
        }
    }
}
