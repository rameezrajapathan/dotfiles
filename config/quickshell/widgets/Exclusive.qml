import QtQuick
import qs.services

Item {
    id: root
    required property var panel
    readonly property bool panelOpen: panel.open

    visible: false
    onPanelOpenChanged: if (enabled && panelOpen) Panels.opened(panel)

    Connections {
        target: Panels
        enabled: root.enabled
        function onOpened(other) {
            if (other !== root.panel && root.panel.open)
                root.panel.open = false;
        }
    }
}
