import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.live
    }

    readonly property var today: Weather.daily[0] ?? null
    readonly property var tomorrow: Weather.daily[1] ?? null
    readonly property real now: clock.date.getTime()
    readonly property real rise: today ? today.sunrise.getTime() : 0
    readonly property real set: today ? today.sunset.getTime() : 0
    readonly property bool day: today !== null && now >= rise && now <= set
    readonly property real progress: !today ? 0.5 : day ? (now - rise) / (set - rise)
        : now > set ? Math.min(1, (now - set) / Math.max(1, (tomorrow ? tomorrow.sunrise.getTime() : set + 12 * 3600000) - set))
        : 0
    readonly property string fmt: Settings.bar.clock24 ? "HH:mm" : "h:mm AP"

    readonly property real synodic: 29.530588853
    readonly property real moonAge: {
        const days = (now - Date.UTC(2000, 0, 6, 18, 14)) / 86400000;
        return ((days % synodic) + synodic) % synodic;
    }
    readonly property real moonPhase: moonAge / synodic
    readonly property real illumination: (1 - Math.cos(2 * Math.PI * moonPhase)) / 2
    readonly property string moonName: {
        const p = moonPhase;
        return p < 0.03 || p > 0.97 ? "New moon" : p < 0.22 ? "Waxing crescent" : p < 0.28 ? "First quarter"
            : p < 0.47 ? "Waxing gibbous" : p < 0.53 ? "Full moon" : p < 0.72 ? "Waning gibbous"
            : p < 0.78 ? "Last quarter" : "Waning crescent";
    }
    readonly property bool wide: width > height * 1.5
    readonly property bool roomy: height > 300

    function length() {
        if (!today)
            return "";
        const m = Math.round((set - rise) / 60000);
        return Math.floor(m / 60) + " h " + (m % 60) + " min of daylight";
    }

    onLiveChanged: if (live) Weather.refreshIfStale()

    component Moon: Canvas {
        property real phase: root.moonPhase
        onPhaseChanged: requestPaint()
        onWidthChanged: requestPaint()
        Connections {
            target: Theme
            function onTextChanged() { requestPaint(); }
        }
        onPaint: {
            const ctx = getContext("2d");
            const r = Math.min(width, height) / 2 - 1;
            const cx = width / 2, cy = height / 2;
            ctx.reset();
            ctx.fillStyle = Qt.alpha(Theme.text, 0.12);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.fill();
            const k = Math.cos(2 * Math.PI * phase);
            const side = phase < 0.5 ? 1 : -1;
            ctx.fillStyle = "#f4ecd8";
            ctx.beginPath();
            ctx.moveTo(cx, cy - r);
            for (let i = 0; i <= 32; i++) {
                const t = -Math.PI / 2 + Math.PI * i / 32;
                ctx.lineTo(cx + side * r * Math.cos(t), cy + r * Math.sin(t));
            }
            for (let i = 0; i <= 32; i++) {
                const t = Math.PI / 2 - Math.PI * i / 32;
                ctx.lineTo(cx + side * k * r * Math.cos(t), cy + r * Math.sin(t));
            }
            ctx.closePath();
            ctx.fill();
        }
    }

    Item {
        id: sky
        anchors { left: parent.left; right: moonBox.visible && root.wide ? moonBox.left : parent.right; top: parent.top; margins: 18 }
        height: root.wide || !root.roomy ? parent.height - 36 - info.height - 8 : (parent.height - 36) * 0.55

        readonly property real rx: Math.max(10, Math.min(width / 2 - 14, height - 26))
        readonly property real cx: width / 2
        readonly property real base: height - 8
        readonly property real angle: Math.PI * (1 - root.progress)
        readonly property point pos: Qt.point(cx + rx * Math.cos(angle), base - rx * Math.sin(angle))

        Rectangle {
            x: 0
            y: sky.base
            width: sky.width
            height: 1
            color: Qt.alpha(Theme.text, 0.18)
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.alpha(Theme.text, 0.22)
                strokeWidth: 2
                strokeStyle: ShapePath.DashLine
                dashPattern: [2, 4]
                fillColor: "transparent"
                startX: sky.cx - sky.rx
                startY: sky.base
                PathArc {
                    x: sky.cx + sky.rx
                    y: sky.base
                    radiusX: sky.rx
                    radiusY: sky.rx
                }
            }
            ShapePath {
                strokeColor: root.day ? Theme.yellow : "transparent"
                strokeWidth: 3
                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                startX: sky.cx - sky.rx
                startY: sky.base
                PathArc {
                    x: sky.pos.x
                    y: sky.pos.y
                    radiusX: sky.rx
                    radiusY: sky.rx
                }
            }
        }

        Rectangle {
            visible: root.day
            x: sky.pos.x - width / 2
            y: sky.pos.y - height / 2
            width: 22
            height: 22
            radius: 11
            color: Theme.yellow
            Rectangle {
                anchors.centerIn: parent
                width: 38
                height: 38
                radius: 19
                color: Qt.alpha(Theme.yellow, 0.22)
                z: -1
            }
        }
        Moon {
            visible: !root.day && !moonBox.visible
            x: sky.pos.x - width / 2
            y: sky.base - sky.rx * 0.55 - height / 2
            width: 26
            height: 26
        }
        Label {
            visible: !Weather.ready
            anchors.centerIn: parent
            text: "Waiting for the weather"
            color: Theme.overlay
        }
    }

    RowLayout {
        id: info
        anchors { left: parent.left; right: moonBox.visible && root.wide ? moonBox.left : parent.right; bottom: root.wide || !root.roomy ? parent.bottom : undefined; top: root.wide || !root.roomy ? undefined : sky.bottom; margins: 18 }
        spacing: 8
        ColumnLayout {
            spacing: 0
            Label { text: "SUNRISE"; color: Theme.overlay; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold; font.letterSpacing: 0.6 }
            Label { text: root.today ? Qt.formatTime(root.today.sunrise, root.fmt) : "–"; font.weight: Font.Bold }
        }
        Item { Layout.fillWidth: true }
        ColumnLayout {
            spacing: 0
            Label { Layout.alignment: Qt.AlignRight; text: "SUNSET"; color: Theme.overlay; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold; font.letterSpacing: 0.6 }
            Label { Layout.alignment: Qt.AlignRight; text: root.today ? Qt.formatTime(root.today.sunset, root.fmt) : "–"; font.weight: Font.Bold }
        }
    }

    Label {
        visible: root.roomy && !root.wide
        anchors { horizontalCenter: parent.horizontalCenter; top: info.bottom; topMargin: 4 }
        text: root.length()
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 1
    }

    ColumnLayout {
        id: moonBox
        visible: root.wide ? root.width > 300 : root.roomy
        anchors {
            right: parent.right
            rightMargin: 18
            verticalCenter: root.wide ? parent.verticalCenter : undefined
            bottom: root.wide ? undefined : parent.bottom
            bottomMargin: 18
            left: root.wide ? undefined : parent.left
            leftMargin: 18
        }
        width: root.wide ? 120 : undefined
        spacing: 6
        Moon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.wide ? 64 : 76
            Layout.preferredHeight: Layout.preferredWidth
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.moonName
            font.weight: Font.DemiBold
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round(root.illumination * 100) + "% lit"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 2
        }
    }
}
