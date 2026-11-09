import Quickshell.Services.SystemTray
import QtQuick
import qs.bar

Flow {
    id: root
    property var cc

    readonly property bool wanted: SystemTray.items.values.length > 0
    visible: wanted
    spacing: 14
    leftPadding: 6
    rightPadding: 6

    Tray { bar: root.cc; all: true }
}
