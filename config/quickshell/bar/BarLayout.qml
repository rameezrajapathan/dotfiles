import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    property int bareShape: -1
    property bool settingsActive: false
    signal action(string name)

    readonly property string layout: Settings.bar.layout
    readonly property bool strip: layout === "full"
    readonly property bool vertical: Theme.barVertical
    readonly property real length: vertical ? height : width
    readonly property real sideGap: layout === "pill" || Theme.barAttached ? 0 : Settings.bar.sideGap
    readonly property real padding: Theme.pillInset + Math.round((1 - Math.min(1, Theme.roundness)) * 6)
    readonly property var shapes: [shape0, shape1, shape2]
    readonly property var rows: [row0, row1, row2]

    readonly property var sections: {
        const b = Settings.bar;
        if (layout !== "pill")
            return [b.left, b.center, b.right];
        let all = [];
        for (const part of [b.left, b.center, b.right].filter(p => p.length))
            all = all.concat(all.length ? ["divider"] : [], part);
        return [[], all, []];
    }

    function anchorFor(ids) {
        for (let i = 0; i < 3; i++) {
            const m = rows[i].find(ids);
            if (m) {
                const index = layout === "islands" ? i : (layout === "pill" ? 1 : 0);
                const p = m.mapToItem(root, m.width / 2, m.height / 2);
                return { index, cx: vertical ? p.y : p.x };
            }
        }
        if (layout === "islands") {
            const index = [1, 0, 2].find(i => shapes[i].visible) ?? 1;
            return { index, cx: shapes[index].along + shapes[index].size / 2 };
        }
        const index = layout === "pill" ? 1 : 0;
        return { index, cx: length / 2 };
    }

    BarShape {
        id: shape0
        bare: root.bareShape === 0
        visible: root.strip || (root.layout === "islands" && row0.hasContent)
        along: root.sideGap
        size: root.strip ? root.length - 2 * root.sideGap : row0.length + 2 * root.padding
    }
    BarShape {
        id: shape1
        bare: root.bareShape === 1
        visible: !root.strip && row1.hasContent
        size: row1.length + 2 * root.padding
        along: row1.along - root.padding
    }
    BarShape {
        id: shape2
        bare: root.bareShape === 2
        visible: root.layout === "islands" && row2.hasContent
        size: row2.length + 2 * root.padding
        along: root.length - root.sideGap - size
    }

    BarRow {
        id: row0
        visible: root.layout !== "pill"
        along: root.sideGap + root.padding
        modules: root.sections[0]
        settingsActive: root.settingsActive
        onAction: name => root.action(name)
    }
    BarRow {
        id: row1
        readonly property real gapBetween: root.strip ? 24 : 2 * root.padding + 10 + 2 * Theme.barEar
        readonly property real minAlong: row0.visible && row0.hasContent ? row0.along + row0.length + gapBetween : 0
        readonly property real maxAlong: row2.visible && row2.hasContent ? row2.along - gapBetween - length : root.length - length
        along: Math.round(Math.max(minAlong, Math.min(maxAlong, (root.length - length) / 2)))
        modules: root.sections[1]
        settingsActive: root.settingsActive
        onAction: name => root.action(name)
    }
    BarRow {
        id: row2
        visible: root.layout !== "pill"
        along: root.length - root.sideGap - root.padding - length
        modules: root.sections[2]
        settingsActive: root.settingsActive
        onAction: name => root.action(name)
    }
}
