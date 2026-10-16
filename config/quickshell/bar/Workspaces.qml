import Quickshell
import QtQuick
import qs.services

Loader {
    id: root
    property string style: Settings.workspaces.style
    property bool vertical: Theme.barVertical
    property bool showSpecial: true
    readonly property string special: showSpecial ? Special.on(QsWindow.window?.screen?.name ?? "") : ""

    sourceComponent: special ? chip : style === "focus" ? focus : strip

    Component { id: focus; WorkspaceFocus {} }
    Component {
        id: strip
        WorkspaceStrip {
            style: root.style
            vertical: root.vertical
        }
    }
    Component {
        id: chip
        SpecialChip {
            name: root.special
            vertical: root.vertical
        }
    }
}
