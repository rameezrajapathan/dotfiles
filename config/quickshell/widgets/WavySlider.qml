import QtQuick
import qs.services

Item {
    id: root
    property real value: 0
    property bool playing: false
    property bool enabled: true
    signal moved(real value)

    readonly property real shown: drag.pressed ? drag.preview : value
    property real phase: 0
    property real amplitude: playing ? 3 : 0
    Behavior on amplitude { NumberAnimation { duration: Theme.ms(300) } }

    implicitHeight: 20
    opacity: enabled ? 1 : 0.5

    NumberAnimation on phase {
        from: 0
        to: 2 * Math.PI
        duration: 2000
        loops: Animation.Infinite
        running: root.playing && root.visible
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const mid = height / 2;
            const x = root.shown * width;
            const gap = 6;
            ctx.lineCap = "round";
            ctx.strokeStyle = Theme.accent;
            ctx.lineWidth = 4;
            ctx.beginPath();
            const end = Math.max(2, x - gap);
            for (let px = 2; px <= end; px += 1) {
                const y = mid + root.amplitude * Math.sin(px / 40 * 2 * Math.PI * 1.25 - root.phase);
                if (px === 2)
                    ctx.moveTo(px, y);
                else
                    ctx.lineTo(px, y);
            }
            if (end > 2)
                ctx.stroke();
            if (x + gap < width - 2) {
                ctx.strokeStyle = Theme.overlay;
                ctx.globalAlpha = 0.5;
                ctx.lineWidth = 4;
                ctx.beginPath();
                ctx.moveTo(x + gap, mid);
                ctx.lineTo(width - 2, mid);
                ctx.stroke();
            }
        }
        Connections {
            target: root
            function onShownChanged() { canvas.requestPaint(); }
            function onPhaseChanged() { canvas.requestPaint(); }
            function onAmplitudeChanged() { canvas.requestPaint(); }
            function onWidthChanged() { canvas.requestPaint(); }
        }
        Connections {
            target: Theme
            function onAccentChanged() { canvas.requestPaint(); }
        }
    }

    Rectangle {
        x: root.shown * root.width - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: drag.pressed ? 22 : 18
        radius: 2
        color: Theme.accent
        Behavior on height { NumberAnimation { duration: Theme.ms(120) } }
    }

    MouseArea {
        id: drag
        property real preview: 0
        anchors.fill: parent
        anchors.margins: -6
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        function at(mx) {
            return Math.max(0, Math.min(1, (mx - 6) / root.width));
        }
        onPressed: mouse => preview = at(mouse.x)
        onPositionChanged: mouse => preview = at(mouse.x)
        onReleased: mouse => root.moved(at(mouse.x))
    }
}
