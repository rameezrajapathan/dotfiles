import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

// Running apps that Super + Q hides instead of closing (Thunderbird, Chrome apps; same list as
// hypr/background.lua). Click: bring a hidden window here, hide a focused one, focus any other.
// Right click quits the app. A dot marks windows that are currently shown.
Repeater {
    id: root
    required property var bar

    readonly property var pattern: /^(org\.mozilla\.Thunderbird|thunderbird|chrome-[a-p]+-.+)$/
    readonly property string hiddenWorkspace: "special:background"

    function appId(t) {
        return t.wayland?.appId ?? t.lastIpcObject?.class ?? "";
    }

    function dispatch(dsp) {
        Quickshell.execDetached(["hyprctl", "dispatch", dsp]);
    }

    model: Hyprland.toplevels.values.filter(t => pattern.test(appId(t)))

    Item {
        id: app
        required property HyprlandToplevel modelData

        readonly property string selector: "address:0x" + modelData.address.replace(/^0x/, "")
        readonly property bool hidden: modelData.workspace?.name === root.hiddenWorkspace
        readonly property string iconPath: {
            const id = root.appId(modelData);
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
                    root.dispatch(`hl.dsp.window.close({ window = "${sel}" })`);
                } else if (app.hidden) {
                    const ws = Hyprland.monitorFor(root.bar.screen)?.activeWorkspace?.id ?? "e+0";
                    root.dispatch(`hl.dsp.window.move({ workspace = "${ws}", window = "${sel}" })`);
                } else if (app.modelData.activated) {
                    root.dispatch(`hl.dsp.window.move({ workspace = "${root.hiddenWorkspace}", silent = true, window = "${sel}" })`);
                } else {
                    root.dispatch(`hl.dsp.focus({ window = "${sel}" })`);
                }
            }
        }
    }
}
