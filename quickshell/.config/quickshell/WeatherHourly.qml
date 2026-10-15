import QtQuick

// The next 24 hours for WeatherPanel: time, icon and temperature over a thin line, and the chance
// of rain when it's worth mentioning. Scrolls sideways (wheel or drag).
Item {
    id: root
    readonly property var hours: Weather.hourly
    readonly property real column: 48
    readonly property real curveTop: 58
    readonly property real curveHeight: 22
    readonly property real minTemp: Math.min(...hours.map(h => h.temp))
    readonly property real maxTemp: Math.max(...hours.map(h => h.temp))

    function pointY(t) {
        const span = Math.max(1, maxTemp - minTemp);
        return curveTop + curveHeight - (t - minTemp) / span * curveHeight;
    }

    implicitHeight: 112

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: root.hours.length * root.column
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Behavior on contentX { NumberAnimation { duration: Theme.ms(250); easing.type: Easing.OutCubic } }

        Canvas {
            id: curve
            width: flick.contentWidth
            height: flick.height
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const hs = root.hours;
                if (hs.length < 2)
                    return;
                const pts = hs.map((h, i) => ({ x: i * root.column + root.column / 2, y: root.pointY(h.temp) }));

                // Smooth line through the points (midpoint quadratic curves)
                ctx.beginPath();
                ctx.moveTo(pts[0].x, pts[0].y);
                for (let i = 1; i < pts.length; i++) {
                    const mx = (pts[i - 1].x + pts[i].x) / 2, my = (pts[i - 1].y + pts[i].y) / 2;
                    ctx.quadraticCurveTo(pts[i - 1].x, pts[i - 1].y, mx, my);
                }
                ctx.lineTo(pts[pts.length - 1].x, pts[pts.length - 1].y);
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                ctx.strokeStyle = Theme.accent;
                ctx.stroke();

                // Now
                ctx.beginPath();
                ctx.arc(pts[0].x, pts[0].y, 4, 0, Math.PI * 2);
                ctx.fillStyle = Theme.accent;
                ctx.fill();
            }

            Connections {
                target: Weather
                function onHourlyChanged() { curve.requestPaint(); }
            }
            Connections {
                target: Theme
                function onAccentChanged() { curve.requestPaint(); }
            }
        }

        Repeater {
            model: root.hours

            Item {
                id: hour
                required property var modelData
                required property int index
                x: index * root.column
                width: root.column
                height: flick.height

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0
                    text: hour.index === 0 ? "now" : Qt.formatTime(hour.modelData.time, "h AP").replace(" ", "").toLowerCase()
                    color: hour.index === 0 ? Theme.accent : Theme.subtext
                    font.pixelSize: Theme.fontSize - 3
                }
                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 18
                    name: Weather.icon(hour.modelData.code, hour.modelData.isDay)
                    size: 18
                    color: Theme.text
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: root.pointY(hour.modelData.temp) + 10
                    text: Weather.temp(hour.modelData.temp)
                    font.pixelSize: Theme.fontSize - 1
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: hour.modelData.precip >= 30 ? hour.modelData.precip + "%" : ""
                    color: Theme.accent
                    font.pixelSize: Theme.fontSize - 3
                }
            }
        }
    }

    // The wheel scrolls sideways
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
            flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, flick.contentX - delta * 1.5));
        }
    }
}
