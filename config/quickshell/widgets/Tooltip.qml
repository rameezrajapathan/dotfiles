import Quickshell
import QtQuick
import qs.services

Item {
    id: root
    property string text
    property string keys: ""
    property string side: "bottom"
    property bool active: true
    property int delay: Settings.accessibility.tooltipDelay

    readonly property bool wanted: active && text !== "" && Settings.accessibility.tooltips && hover.hovered && root.visible
    property bool shown: false
    property bool inWindow: false
    property point spot: Qt.point(0, 0)
    property Item host: null

    anchors.fill: parent

    onWantedChanged: {
        if (wanted)
            showTimer.restart();
        else {
            showTimer.stop();
            shown = false;
        }
    }

    function place() {
        let host = root.parent;
        while (host && host.parent)
            host = host.parent;
        root.host = host;
        const w = bubble.implicitWidth;
        const h = bubble.implicitHeight;
        if (!host || host.width < w + 16 || host.height < 120) {
            inWindow = false;
            return;
        }
        const gap = 6;
        const tl = root.mapToItem(host, 0, 0);
        const cx = tl.x + root.width / 2;
        const cy = tl.y + root.height / 2;
        const fits = s => s === "bottom" ? tl.y + root.height + gap + h <= host.height
            : s === "top" ? tl.y - gap - h >= 0
            : s === "right" ? tl.x + root.width + gap + w <= host.width
            : tl.x - gap - w >= 0;
        const opposite = ({ bottom: "top", top: "bottom", left: "right", right: "left" })[side] ?? "top";
        const s = fits(side) ? side : fits(opposite) ? opposite : "";
        if (!s) {
            inWindow = false;
            return;
        }
        let x = s === "left" ? tl.x - gap - w : s === "right" ? tl.x + root.width + gap : cx - w / 2;
        let y = s === "top" ? tl.y - gap - h : s === "bottom" ? tl.y + root.height + gap : cy - h / 2;
        x = Math.max(4, Math.min(host.width - w - 4, x));
        y = Math.max(4, Math.min(host.height - h - 4, y));
        spot = Qt.point(Math.round(x), Math.round(y));
        inWindow = true;
    }

    Timer {
        id: showTimer
        interval: Math.max(0, root.delay)
        onTriggered: {
            if (!root.wanted)
                return;
            root.place();
            root.shown = true;
        }
    }

    Timer {
        running: root.shown
        interval: 6000
        onTriggered: root.shown = false
    }

    HoverHandler {
        id: hover
        enabled: root.active && root.text !== ""
    }

    TooltipBubble {
        id: bubble
        parent: root.shown && root.inWindow && root.host ? root.host : root
        visible: root.shown && root.inWindow
        x: root.spot.x
        y: root.spot.y
        z: 1000
        text: root.text
        keys: root.keys
    }

    LazyLoader {
        active: root.shown && !root.inWindow

        PopupWindow {
            readonly property int gap: 6
            anchor.item: root
            anchor.rect.x: root.side === "left" ? -gap : root.side === "right" ? root.width + gap : 0
            anchor.rect.y: root.side === "top" ? -gap : root.side === "bottom" ? root.height + gap : 0
            anchor.rect.width: root.side === "left" || root.side === "right" ? 1 : root.width
            anchor.rect.height: root.side === "top" || root.side === "bottom" ? 1 : root.height
            anchor.edges: root.side === "top" ? Edges.Top : root.side === "left" ? Edges.Left : root.side === "right" ? Edges.Right : Edges.Bottom
            anchor.gravity: anchor.edges
            anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
            implicitWidth: popupBubble.implicitWidth
            implicitHeight: popupBubble.implicitHeight
            color: "transparent"
            mask: Region {}
            visible: true

            TooltipBubble {
                id: popupBubble
                width: parent.width
                height: parent.height
                text: root.text
                keys: root.keys
            }
        }
    }
}

