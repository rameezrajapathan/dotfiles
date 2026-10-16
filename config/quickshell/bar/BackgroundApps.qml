import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.services

Repeater {
    id: root
    required property var bar

    model: Background.windows

    Item {
        id: app
        required property HyprlandToplevel modelData

        readonly property string selector: Background.selector(modelData)
        readonly property bool hidden: Background.isHidden(modelData)
        readonly property string iconPath: {
            const id = Background.appId(modelData);
            const icon = DesktopEntries.heuristicLookup(id)?.icon ?? id;
            return Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : Quickshell.iconPath(icon, "application-x-executable");
        }

        implicitWidth: 18
        implicitHeight: 18

        IconImage {
            anchors.fill: parent
            source: app.iconPath
        }

        Rectangle {
            visible: !app.hidden
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 2
            width: 4
            height: 4
            radius: 2
            color: Theme.accent
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                const sel = app.selector;
                if (mouse.button === Qt.RightButton) {
                    Background.dispatch(`hl.dsp.window.close({ window = "${sel}" })`);
                } else if (app.hidden) {
                    const ws = Hyprland.monitorFor(root.bar.screen)?.activeWorkspace?.id ?? "e+0";
                    Background.dispatch(`hl.dsp.window.move({ workspace = "${ws}", window = "${sel}" })`);
                    Background.dispatch(`hl.dsp.focus({ window = "${sel}" })`);
                } else if (app.modelData.activated) {
                    Quickshell.execDetached(["hyprctl", "eval", "require('background').hide_or_close()"]);
                } else {
                    Background.dispatch(`hl.dsp.focus({ window = "${sel}" })`);
                }
            }
        }
    }
}
