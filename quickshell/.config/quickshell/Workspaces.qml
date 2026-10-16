import QtQuick

// The bar's workspace indicator, in the style picked in Settings > Bar > Workspaces
// (WorkspaceStyles.qml): WorkspaceFocus.qml for "focus", WorkspaceStrip.qml for the rest.
// `style` and `vertical` can be set to show a style other than the picked one (Settings previews).
Loader {
    id: root
    property string style: Settings.workspaces.style
    property bool vertical: Theme.barVertical

    sourceComponent: style === "focus" ? focus : strip

    Component { id: focus; WorkspaceFocus {} }
    Component {
        id: strip
        WorkspaceStrip {
            style: root.style
            vertical: root.vertical
        }
    }
}
