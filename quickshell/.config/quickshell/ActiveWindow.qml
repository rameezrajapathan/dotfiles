import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

// App icon and title of the focused window, shown only on the bar of the monitor it's on.
Row {
    id: root
    required property var screen
    property int maxWidth: 500

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var toplevel: {
        const t = Hyprland.activeToplevel;
        return t && t.workspace && t.workspace === monitor?.activeWorkspace ? t : null;
    }
    readonly property string appId: toplevel?.wayland?.appId ?? toplevel?.lastIpcObject?.class ?? ""
    readonly property string iconPath: {
        const entry = appId ? DesktopEntries.heuristicLookup(appId) : null;
        const icon = entry?.icon ?? appId;
        return Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : "";
    }

    spacing: 8
    visible: toplevel !== null

    IconImage {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.iconPath !== ""
        source: root.iconPath
        implicitSize: 16
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, root.maxWidth)
        text: root.toplevel?.title || root.appId
        elide: Text.ElideRight
    }
}
