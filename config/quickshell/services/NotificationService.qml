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
        if (action)
            action.invoke();
        hidePopup(n);
    }

    function ago(n) {
        return TimeDate.ago(times[n.id]);
    }

    function iconFor(n) {
        const themed = n.image.startsWith("image://icon/") ? n.image.slice(13) : "";
        if (n.image && !themed)
            return n.image;
        const icon = themed || n.appIcon;
        if (!icon)
            return "";
        return icon.startsWith("/") ? "file://" + icon : Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : "";
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void {
            Panels.toggle("controlcenter", "notifications");
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
