import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.widgets

RowLayout {
    readonly property var window: ToplevelManager.activeToplevel

    spacing: 6

    AppIcon {
        icon: window?.appId ?? ""
        implicitSize: 16
    }
    Label {
        Layout.maximumWidth: 220
        text: window?.title ?? ""
        elide: Text.ElideRight
    }
}
