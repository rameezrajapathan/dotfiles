import QtQuick

// The bar's shapes and items across the screen's width, as Settings.bar describes them:
//   pill     one centered pill holding every section (dividers between them)
//   islands  a pill per section: left, middle, right
//   full     one bar from side to side, sections at its left, middle and right
// Bar.qml shows it; Sheet.qml draws a copy over drop-down sheets so they look attached, with
// `bareShape` (the shape the sheet comes out of) left for the sheet to draw.
Item {
    id: root
    // Index into `shapes` whose background the Sheet draws itself
    property int bareShape: -1
    property bool settingsActive: false
    signal action(string name)

    readonly property string layout: Settings.bar.layout
    readonly property bool strip: layout === "full"
    readonly property real sideGap: layout === "pill" ? 0 : Settings.bar.sideGap
    readonly property real padding: Theme.pillInset + Math.round((1 - Settings.bar.roundness) * 6)
    readonly property var shapes: [shape0, shape1, shape2]
    readonly property var rows: [row0, row1, row2]

    readonly property var sections: {
        const b = Settings.bar;
        if (layout !== "pill")
            return [b.left, b.center, b.right];
        // Joined into one row, a divider between sections
        let all = [];
        for (const part of [b.left, b.center, b.right].filter(p => p.length))
            all = all.concat(all.length ? ["divider"] : [], part);
        return [[], all, []];
    }

    height: Theme.barHeight

    // Which shape a sheet for `ids` (module ids, in order of preference) comes out of, and the
    // middle of that module (or of the shape); { index, cx }
    function anchorFor(ids) {
        for (let i = 0; i < 3; i++) {
            const m = rows[i].find(ids);
            if (m) {
                const index = layout === "islands" ? i : (layout === "pill" ? 1 : 0);
                return { index, cx: m.mapToItem(root, m.width / 2, 0).x };
            }
        }
        // Not on the bar: the middle pill (or the first one shown), or the bar's middle
        if (layout === "islands") {
            const index = [1, 0, 2].find(i => shapes[i].visible) ?? 1;
            return { index, cx: shapes[index].x + shapes[index].width / 2 };
        }
        const index = layout === "pill" ? 1 : 0;
        return { index, cx: width / 2 };
    }

    // full: the whole bar; islands: the left pill
    BarShape {
        id: shape0
        bare: root.bareShape === 0
        visible: root.strip || (root.layout === "islands" && row0.hasContent)
        x: root.sideGap
        width: root.strip ? root.width - 2 * root.sideGap : row0.implicitWidth + 2 * root.padding
    }
    // pill: the pill; islands: the middle one
    BarShape {
        id: shape1
        bare: root.bareShape === 1
        visible: !root.strip && row1.hasContent
        width: row1.implicitWidth + 2 * root.padding
        x: row1.x - root.padding
    }
    // islands: the right pill
    BarShape {
        id: shape2
        bare: root.bareShape === 2
        visible: root.layout === "islands" && row2.hasContent
        width: row2.implicitWidth + 2 * root.padding
        x: root.width - root.sideGap - width
    }

    BarRow {
        id: row0
        visible: root.layout !== "pill"
        x: root.sideGap + root.padding
        y: Theme.barGap + (Theme.pillHeight - height) / 2
        modules: root.sections[0]
        settingsActive: root.settingsActive
        onAction: name => root.action(name)
    }
    // Centered, but pushed aside rather than overlapping a long left or right section
    BarRow {
        id: row1
        readonly property real gapBetween: root.strip ? 24 : 2 * root.padding + 10
        readonly property real minX: row0.visible && row0.hasContent ? row0.x + row0.width + gapBetween : 0
        readonly property real maxX: row2.visible && row2.hasContent ? row2.x - gapBetween - width : root.width - width
        x: Math.round(Math.max(minX, Math.min(maxX, (root.width - width) / 2)))
        y: Theme.barGap + (Theme.pillHeight - height) / 2
        modules: root.sections[1]
        settingsActive: root.settingsActive
        onAction: name => root.action(name)
    }
    BarRow {
        id: row2
        visible: root.layout !== "pill"
        x: root.width - root.sideGap - root.padding - width
        y: Theme.barGap + (Theme.pillHeight - height) / 2
        modules: root.sections[2]
        settingsActive: root.settingsActive
        onAction: name => root.action(name)
    }
}
