import Quickshell
import QtQuick
import qs.services
import qs.widgets

Item {
    id: item
    required property string key
    required property var dock

    readonly property var info: Dock.items.find(i => i.key === key) ?? null
    readonly property var p: dock.layout.pos[key] ?? null
    readonly property string kind: info?.kind ?? "app"
    readonly property var group: Dock.groups.map[key] ?? null
    readonly property var windows: group?.windows ?? []
    readonly property var entry: kind === "app" ? Dock.entry(key) : null
    readonly property bool running: windows.length > 0
    readonly property bool focused: windows.some(t => t.activated)
    readonly property string special: running && windows.every(t => Dock.isSpecial(t)) ? Dock.specialName(windows[0]) : ""
    readonly property bool dragging: dock.dragKey === key
    readonly property bool removing: dock.removingKey === key
    readonly property bool launching: Dock.launching[key] !== undefined && !running
    readonly property real size: p?.size ?? dock.iconSize
    readonly property real thickness: kind === "divider" ? dock.iconSize * 0.62 : size
    readonly property real lift: dragging ? Math.max(0, dock.dragOut - size / 2 - Dock.gap - Dock.pad) : 0

    property real along: dragging ? dock.dragAlong - size / 2 : (p?.along ?? 0)
    Behavior on along {
        enabled: !item.dragging && !item.dock.magnifying
        NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic }
    }

    readonly property rect r: dock.rect(along, size, Dock.gap + (kind === "divider" ? (dock.depth - thickness) / 2 : Dock.pad) - dock.slide + lift, thickness)
    x: r.x
    y: r.y
    width: r.width
    height: r.height
    z: dragging ? 10 : 0
    visible: p !== null && dock.progress > 0
    opacity: removing ? 0 : dock.dragRemoving && dragging ? 0.45 : 1
    Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }

    Rectangle {
        visible: item.kind === "divider"
        anchors.centerIn: parent
        width: item.dock.vertical ? parent.width : 1
        height: item.dock.vertical ? 1 : parent.height
        color: Qt.alpha(Theme.text, 0.22)
    }

    DockIndicator {
        visible: item.kind === "app" && item.running
        target: icon
        edge: item.dock.edge
        count: Dock.cfg.indicatorCount ? Math.min(3, item.windows.length) : 1
        active: item.focused
    }

    Item {
        id: icon
        visible: item.kind !== "divider"
        anchors.fill: parent

        property real pulse: 1
        opacity: pulse

        SequentialAnimation on pulse {
            running: item.launching && Dock.cfg.launchPulse && !Theme.reduceMotion
            loops: Animation.Infinite
            onRunningChanged: if (!running) icon.pulse = 1
            NumberAnimation { to: 0.45; duration: 520; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 520; easing.type: Easing.InOutSine }
        }

        AppIcon {
            visible: item.kind === "app"
            anchors.fill: parent
            implicitSize: Math.ceil(item.dock.iconSize * Dock.magnifyScale)
            icon: item.entry?.icon ?? item.group?.appId ?? ""
        }

        Rectangle {
            visible: item.kind === "launcher"
            anchors.fill: parent
            anchors.margins: parent.width * 0.06
            radius: Theme.round(width * 0.28, width, height)
            color: Qt.alpha(Theme.text, mouse.containsMouse ? 0.18 : 0.1)
            Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

            Icon {
                anchors.centerIn: parent
                name: "apps"
                size: Math.round(parent.width * 0.5)
            }
        }

        Rectangle {
            visible: item.special !== ""
            readonly property real d: Math.max(16, Math.round(item.size * 0.34))
            width: d
            height: d
            radius: d / 2
            x: item.dock.edge === "right" ? -2 : parent.width - d + 2
            y: -2
            color: Theme.special

            Icon {
                anchors.centerIn: parent
                name: Special.info(item.special).icon
                filled: true
                size: Math.round(parent.d * 0.66)
                color: Theme.specialText
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: item.kind !== "divider"
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: item.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        property point origin
        property bool moved: false

        onContainsMouseChanged: item.dock.itemHover(item.key, containsMouse)
        onPressed: event => {
            origin = mapToItem(item.dock.canvas, event.x, event.y);
            moved = false;
        }
        onPositionChanged: event => {
            if (!pressed || !(pressedButtons & Qt.LeftButton) || item.kind !== "app")
                return;
            const c = mapToItem(item.dock.canvas, event.x, event.y);
            if (!moved && Math.hypot(c.x - origin.x, c.y - origin.y) < 8)
                return;
            if (!moved) {
                moved = true;
                item.dock.beginDrag(item.key);
            }
            item.dock.moveDrag(c);
        }
        onReleased: {
            if (moved)
                item.dock.endDrag();
        }
        onClicked: event => {
            if (moved)
                return;
            if (event.button === Qt.RightButton)
                item.dock.openMenu(item.key);
            else if (event.button === Qt.MiddleButton) {
                if (item.kind === "app")
                    Dock.newWindow(item.key);
            } else
                item.dock.activate(item.key);
        }
    }
}
