import QtQuick

// A small sketch of a bar setup (a BarStyles preset or Settings.bar) over a stand-in wallpaper,
// for the style cards in Settings > Bar. Items are drawn as dots and dashes.
Item {
    id: root
    // { layout, left, center, right, height, gap, sideGap, roundness, border }
    property var config
    // Preview pixels per screen pixel
    readonly property real k: 0.42

    readonly property real barH: Math.max(8, (config.height - 2 * Math.min(config.gap, (config.height - 24) / 2)) * k)
    readonly property real gap: Math.min(config.gap, (config.height - 24) / 2) * k
    readonly property real side: config.layout === "pill" ? 0 : config.sideGap * k + 3
    readonly property real r: barH / 2 * config.roundness
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

    // Stand-in wallpaper
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.35) }
            GradientStop { position: 1; color: Qt.alpha(Theme.overlay, 0.25) }
        }
    }
    // A window under the bar
    Rectangle {
        x: 10
        y: root.gap + root.barH + 6
        width: parent.width - 20
        height: parent.height
        radius: 4
        color: Qt.alpha(Theme.base, 0.5)
    }

    component Shape: Rectangle {
        y: root.gap
        height: root.barH
        radius: root.r
        color: Theme.base
        border.width: root.config.border ? 1 : 0
        border.color: Qt.alpha(Theme.overlay, 0.6)
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
