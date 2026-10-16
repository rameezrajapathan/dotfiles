import Quickshell.Services.SystemTray
import QtQuick

// Control center widget: background apps and tray icons. Hidden when there are none.
Flow {
    id: root
    property var cc

    readonly property bool wanted: SystemTray.items.values.length > 0 || backgroundApps.count > 0
    visible: wanted
    spacing: 14
    leftPadding: 6
    rightPadding: 6

    BackgroundApps { id: backgroundApps; bar: root.cc }
    Tray { bar: root.cc }
}
