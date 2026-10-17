import QtQuick

Rectangle {
    id: root
    property Flickable target
    property real size: 40
    readonly property bool needed: target && (target.contentHeight > target.height + 1 || target.contentWidth > target.width + 1)
    readonly property bool horizontal: target && target.contentWidth > target.width + 1
    readonly property real edge: Math.min(0.5, size / Math.max(1, horizontal ? width : height))

    visible: false
    layer.enabled: true
    width: target?.width ?? 0
    height: target?.height ?? 0
    gradient: Gradient {
        orientation: root.horizontal ? Gradient.Horizontal : Gradient.Vertical
        GradientStop { position: 0; color: !root.target || (root.horizontal ? root.target.atXBeginning : root.target.atYBeginning) ? "black" : "transparent" }
        GradientStop { position: root.edge; color: "black" }
        GradientStop { position: 1 - root.edge; color: "black" }
        GradientStop { position: 1; color: !root.target || (root.horizontal ? root.target.atXEnd : root.target.atYEnd) ? "black" : "transparent" }
    }
}
