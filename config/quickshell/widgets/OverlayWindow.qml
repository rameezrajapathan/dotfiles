import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.services

PanelWindow {
    id: root

    property bool open: false
    property string layerNamespace: "quickshell-overlay"
    property real backdropOpacity: 0.3
    property int fadeDuration: Theme.ms(180)
    property bool hideWhenFaded: true
    property bool closeOnBackdrop: true
    property bool exclusive: true
    signal opening()
    signal backdropClicked()

    function toggle() {
        if (open) {
            open = false;
            return;
        }
        opening();
        visible = true;
        open = true;
    }

    Exclusive {
        panel: root
        enabled: root.exclusive
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: root.layerNamespace
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.open ? root.backdropOpacity : 0
        Behavior on opacity { NumberAnimation { duration: root.fadeDuration } }
        onOpacityChanged: if (root.hideWhenFaded && opacity === 0 && !root.open) root.visible = false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.backdropClicked();
            if (root.closeOnBackdrop)
                root.open = false;
        }
    }
}
