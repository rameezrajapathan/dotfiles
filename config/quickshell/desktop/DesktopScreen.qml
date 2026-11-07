import Quickshell
import QtQuick

Scope {
    id: root
    required property var modelData

    DesktopWindow {
        modelData: root.modelData
    }

    DesktopWindow {
        modelData: root.modelData
        raisedLayer: true
    }
}
