import QtQuick

// Put inside a panel that has an `open` property (e.g. `Exclusive { panel: root }`): opening it
// closes whichever other panel is open (Panels.qml).
Item {
    id: root
    required property var panel
    readonly property bool panelOpen: panel.open

    visible: false
    onPanelOpenChanged: if (panelOpen) Panels.opened(panel)

    Connections {
        target: Panels
        function onOpened(other) {
            if (other !== root.panel && root.panel.open)
                root.panel.open = false;
        }
    }
}
