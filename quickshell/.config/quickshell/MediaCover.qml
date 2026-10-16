import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// The album art in a scalloped "cookie" (9 soft bumps), turning slowly while music plays, with the
// spectrum (Cava) drawn as rounded bars radiating from its edge. Without art: the accent cookie and
// a music icon. Used by MediaPanel.qml.
Item {
    id: root
    property string art: ""
    property bool playing: false
    // Cookie size; the bars use the room around it
    property real coverSize: 190
    property string icon: "music_note"
    // Room around the cookie for the spectrum bars; 0 = no bars
    property real barRoom: 90

    readonly property int bumps: 9
    readonly property real depth: 0.07
    readonly property real coverRadius: coverSize / 2
    property real turn: 0

    // Distance from the center to the cookie's edge at `angle` (radians, before turning)
    function edge(angle) {
        return coverRadius * (1 - depth + depth * Math.cos(bumps * angle));
    }

    implicitWidth: coverSize + barRoom
    implicitHeight: implicitWidth

    // One turn every 40 s while playing; stays where it is when paused
    NumberAnimation on turn {
        from: 0
        to: 360
        duration: 40000
        loops: Animation.Infinite
        running: root.playing && root.visible
        paused: running && !root.playing
    }

    // Spectrum bars around the cookie
    Canvas {
        id: bars
        visible: root.barRoom > 0
        anchors.fill: parent
        readonly property var levels: Cava.levels
        onLevelsChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const n = Cava.barCount;
            const cx = width / 2, cy = height / 2;
            const room = (width - root.coverSize) / 2 - 10;
            ctx.strokeStyle = Theme.accent;
            ctx.lineCap = "round";
            ctx.lineWidth = Math.max(2, 2 * Math.PI * root.coverRadius / n * 0.42);
            const rot = root.turn * Math.PI / 180;
            for (let i = 0; i < n; i++) {
                const a = i * 2 * Math.PI / n - Math.PI / 2;
                const v = Math.max(0.02, Math.min(1, (levels[i] ?? 0)));
                const r0 = root.edge(a - rot) + 8;
                const r1 = r0 + v * room;
                ctx.globalAlpha = 0.35 + 0.65 * v;
                ctx.beginPath();
                ctx.moveTo(cx + r0 * Math.cos(a), cy + r0 * Math.sin(a));
                ctx.lineTo(cx + r1 * Math.cos(a), cy + r1 * Math.sin(a));
                ctx.stroke();
            }
        }
    }

    // The cookie's outline (unturned), shared by the backdrop and the mask
    readonly property var outline: {
        const pts = [];
        const c = coverRadius;
        for (let i = 0; i <= 180; i++) {
            const a = i * 2 * Math.PI / 180;
            const r = edge(a);
            pts.push(Qt.point(c + r * Math.cos(a), c + r * Math.sin(a)));
        }
        return pts;
    }

    // Backdrop: art with see-through or white edges still shows the shape
    Shape {
        id: cookie
        anchors.centerIn: parent
        width: root.coverSize
        height: root.coverSize
        rotation: root.turn
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Qt.alpha(Theme.accent, 0.22)
            strokeWidth: -1
            PathPolyline { path: root.outline }
        }
    }

    // Opaque copy used as the art's mask
    Shape {
        id: mask
        anchors.fill: cookie
        rotation: root.turn
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4
        visible: false

        ShapePath {
            fillColor: "white"
            strokeWidth: -1
            PathPolyline { path: root.outline }
        }
    }

    Image {
        id: art
        anchors.fill: cookie
        source: root.art
        sourceSize: Qt.size(root.coverSize * 2, root.coverSize * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: cookie
        source: art
        visible: art.status === Image.Ready
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Icon {
        anchors.centerIn: parent
        visible: art.status !== Image.Ready
        name: root.icon
        size: root.coverSize * 0.32
        color: Theme.accent
    }
}
