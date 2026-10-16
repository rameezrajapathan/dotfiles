import Quickshell
import Quickshell.Widgets
import QtQuick

IconImage {
    property string icon
    implicitSize: 28
    source: icon.startsWith("/") ? "file://" + icon
        : Quickshell.iconPath(icon && Quickshell.hasThemeIcon(icon) ? icon : "application-x-executable")
    asynchronous: true
}
