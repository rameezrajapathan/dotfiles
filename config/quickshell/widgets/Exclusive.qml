import QtQuick
import qs.services

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
