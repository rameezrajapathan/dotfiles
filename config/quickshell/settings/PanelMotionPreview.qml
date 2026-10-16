import QtQuick
import qs.services
import qs.widgets

Rectangle {
    id: root
    property string style: "slide"
    property bool running: true

    property real p: 0
    readonly property var g: PanelMotion.shape(style, p)
    readonly property real shown: PanelMotion.clamp(p)
    readonly property var info: PanelMotion.info(style)

    readonly property real pillWidth: 54
    readonly property real pillHeight: 14
    readonly property real bodyWidth: Math.min(width - 24, 104)
    readonly property real bodyHeight: height - pillHeight - 16
    readonly property real bodyTop: 5 + pillHeight
    readonly property real curWidth: pillWidth + (bodyWidth - pillWidth) * g.w
    readonly property real curHeight: Math.max(0, bodyHeight * g.h)

    implicitHeight: 104
    radius: Theme.round(10, width, height)
    color: Qt.alpha(Theme.base, 0.7)
    clip: true

    SequentialAnimation on p {
        running: root.running && root.visible
        loops: Animation.Infinite
        onRunningChanged: if (!running) root.p = 1
        NumberAnimation {
            to: 1
            duration: PanelMotion.openDuration(root.style)
            easing.type: root.info.easing
            easing.overshoot: root.info.overshoot ?? 1.70158
        }
        PauseAnimation { duration: 1100 }
        NumberAnimation { to: 0; duration: PanelMotion.closeDuration(); easing.type: Easing.OutCubic }
        PauseAnimation { duration: 600 }
    }

    Item {
        x: (root.width - root.curWidth) / 2
        y: root.bodyTop
        width: root.curWidth
        height: root.curHeight
        clip: true

        Rectangle {
            y: root.g.y * root.bodyHeight
            width: parent.width
            height: root.g.reveal || root.g.h >= 1 ? root.bodyHeight : root.curHeight
            radius: Theme.round(9, width, height)
            topLeftRadius: Theme.round(9 * PanelMotion.clamp((root.curWidth - root.pillWidth) / 20), width, height)
            topRightRadius: topLeftRadius
            color: Theme.surface
            opacity: root.g.body
            transform: Scale {
                origin.x: root.curWidth / 2
                xScale: root.g.bodyScale
                yScale: root.g.bodyScale
            }
        }

        Item {
            x: (root.curWidth - root.bodyWidth) / 2
            y: root.g.y * root.bodyHeight + root.g.cy
            width: root.bodyWidth
            height: root.bodyHeight
            opacity: root.g.content * root.g.body
            scale: root.g.scale
            transformOrigin: Item.Top

            Rectangle { x: 8; y: 8; width: 10; height: 10; radius: Theme.round(5, width, height); color: Theme.overlay }
            Rectangle { x: 22; y: 10; width: 36; height: 5; radius: Theme.round(2.5, width, height); color: Theme.overlay }
            Grid {
                x: 8
                y: 24
                columns: 2
                spacing: 4
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        width: (root.bodyWidth - 20) / 2
                        height: 14
                        radius: Theme.round(5, width, height)
                        color: index === 0 || index === 3 ? Theme.accent : Qt.alpha(Theme.base, 0.6)
                    }
                }
            }
            Rectangle {
                x: 8; y: 62; width: root.bodyWidth - 16; height: 8; radius: 4
                color: Qt.alpha(Theme.base, 0.6)
                Rectangle { width: parent.width * 0.62; height: parent.height; radius: Theme.round(4, width, height); color: Theme.accent }
            }
        }
    }

    Rectangle {
        x: (root.width - root.pillWidth) / 2
        y: 5
        width: root.pillWidth
        height: root.pillHeight + root.shown
        color: Theme.surface
        topLeftRadius: Theme.round(root.pillHeight / 2, width, height)
        topRightRadius: Theme.round(root.pillHeight / 2, width, height)
        bottomLeftRadius: Theme.round(root.pillHeight / 2 * (1 - root.shown), width, height)
        bottomRightRadius: Theme.round(root.pillHeight / 2 * (1 - root.shown), width, height)

        Rectangle { x: 4; anchors.verticalCenter: parent.verticalCenter; width: 7; height: 7; radius: Theme.round(3.5, width, height); color: Theme.accent }
        Rectangle { anchors.centerIn: parent; width: 18; height: 3; radius: Theme.round(1.5, width, height); color: Theme.overlay }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter; width: 7; height: 7; radius: Theme.round(3.5, width, height); color: Theme.overlay }
    }
}
