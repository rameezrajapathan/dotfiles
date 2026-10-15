import Quickshell
import Quickshell.Widgets
import QtQuick

// An app's icon from its desktop entry Icon= value (theme name or path), with a generic fallback.
IconImage {
    property string icon
    implicitSize: 28
    source: icon.startsWith("/") ? "file://" + icon
        : Quickshell.iconPath(icon && Quickshell.hasThemeIcon(icon) ? icon : "application-x-executable")
    asynchronous: true
}
