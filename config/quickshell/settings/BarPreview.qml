import QtQuick
import qs.bar
import qs.services
import qs.widgets

Item {
    id: root
    property var config
    readonly property real k: 0.42

    readonly property bool attached: config.attached ?? Settings.bar.attached
    readonly property real innerGap: Math.min(config.gap, (config.height - 24) / 2)
    readonly property real barH: Math.max(8, (config.height - (attached ? 1 : 2) * innerGap) * k)
    readonly property real gap: attached ? 0 : innerGap * k
    readonly property real side: config.layout === "pill" ? 0 : attached ? 0 : config.sideGap * k + 3
    readonly property real r: Theme.round(barH / 2, barH, barH)
    readonly property real ear: attached ? Math.max(3, Math.min(r, 6)) : 0
    readonly property var sections: {
        if (config.layout !== "pill")
            return [config.left, config.center, config.right];
        let all = [];
        for (const part of [config.left, config.center, config.right].filter(p => p.length))
            all = all.concat(all.length ? ["divider"] : [], part);
        return [[], all, []];
    }

    implicitHeight: 64
    clip: true

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.35) }
            GradientStop { position: 1; color: Qt.alpha(Theme.overlay, 0.25) }
        }
    }
    Rectangle {
        x: 10
        y: root.gap + root.barH + 6
        width: parent.width - 20
        height: parent.height
        radius: Theme.round(4, width, height)
        color: Qt.alpha(Theme.base, 0.5)
        GlassRim {}
    }

    component Shape: Rectangle {
        id: shape
        readonly property bool flushStart: root.attached && x < 1
        readonly property bool flushEnd: root.attached && x + width > root.width - 1
        y: root.gap
        height: root.barH
        radius: root.r
        topLeftRadius: root.attached ? 0 : root.r
        topRightRadius: root.attached ? 0 : root.r
        bottomLeftRadius: flushStart ? 0 : root.r
        bottomRightRadius: flushEnd ? 0 : root.r
        color: Theme.base
        border.width: root.config.border && !root.attached ? 1 : 0
        border.color: Qt.alpha(Theme.overlay, 0.6)

        BarEars {
            x: -shape.x
            along: shape.x
            size: shape.width
            thickness: shape.height
            ear: root.ear
            flushStart: shape.flushStart
            flushEnd: shape.flushEnd
            color: shape.color
        }
    }

    Shape {
        visible: root.config.layout === "full"
        x: root.side
        width: root.width - 2 * root.side
    }
    Shape {
        visible: root.config.layout === "islands" && root.sections[0].length > 0
        x: root.side
        width: row0.width + 2 * root.barH * 0.3
    }
    Shape {
        visible: root.config.layout !== "full" && root.sections[1].length > 0
        width: row1.width + 2 * root.barH * 0.3
        x: (root.width - width) / 2
    }
    Shape {
        visible: root.config.layout === "islands" && root.sections[2].length > 0
        width: row2.width + 2 * root.barH * 0.3
        x: root.width - root.side - width
    }

    BarPreviewRow {
        barH: root.barH
        y: root.gap
        id: row0
        x: root.side + root.barH * 0.3
        modules: root.sections[0]
    }
    BarPreviewRow {
        barH: root.barH
        y: root.gap
        id: row1
        x: (root.width - width) / 2
        modules: root.sections[1]
    }
    BarPreviewRow {
        barH: root.barH
        y: root.gap
        id: row2
        x: root.width - root.side - root.barH * 0.3 - width
        modules: root.sections[2]
    }
}
