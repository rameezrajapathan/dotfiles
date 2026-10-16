import Quickshell
import QtQuick

// The bar's workspace indicator, in the style picked in Settings > Bar > Workspaces
// (WorkspaceStyles.qml): WorkspaceFocus.qml for "focus", WorkspaceStrip.qml for the rest. While a
// special workspace is open on this monitor it shows SpecialChip.qml instead.
// `style` and `vertical` can be set to show a style other than the picked one (Settings previews,
// which also turn `showSpecial` off).
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
