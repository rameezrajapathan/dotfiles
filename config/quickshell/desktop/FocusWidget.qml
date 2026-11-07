import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true

    readonly property bool wide: width > height * 1.4
    readonly property real ring: Math.min(wide ? height - 36 : width - 40, wide ? width * 0.45 : height - 96)
    readonly property real fraction: Desktop.focusTotal > 0 ? Desktop.focusLeft / Desktop.focusTotal : 0
    readonly property color tint: Desktop.focusMode === "focus" ? Theme.accent : Theme.green
    readonly property string label: Desktop.focusMode === "focus" ? "Focus" : Desktop.focusMode === "long" ? "Long break" : "Break"
    readonly property string clockText: Math.floor(Desktop.focusLeft / 60) + ":" + String(Desktop.focusLeft % 60).padStart(2, "0")

    component Button: Rectangle {
        id: button
        property string icon
        property bool big: false
        property string tip
        signal clicked()
        implicitWidth: big ? 46 : 36
        implicitHeight: implicitWidth
        radius: width / 2
        color: big ? root.tint : mouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.surface, 0.5)
        Icon {
            anchors.centerIn: parent
            name: button.icon
            filled: true
            size: button.big ? 26 : 20
            color: button.big ? Theme.accentText : Theme.text
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
        Tooltip {
            text: button.tip
        }
    }

    GridLayout {
        anchors.centerIn: parent
        columns: root.wide ? 2 : 1
        columnSpacing: 22
        rowSpacing: 10

        Item {
            Layout.alignment: Qt.AlignCenter
            implicitWidth: root.ring
            implicitHeight: root.ring

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                readonly property real r: width / 2 - 6
                ShapePath {
                    strokeColor: Qt.alpha(Theme.text, 0.1)
                    strokeWidth: 8
                    fillColor: "transparent"
                    PathAngleArc { centerX: root.ring / 2; centerY: root.ring / 2; radiusX: root.ring / 2 - 6; radiusY: root.ring / 2 - 6; startAngle: 0; sweepAngle: 360 }
                }
                ShapePath {
                    strokeColor: root.tint
                    strokeWidth: 8
                    capStyle: ShapePath.RoundCap
                    fillColor: "transparent"
                    PathAngleArc {
                        centerX: root.ring / 2
                        centerY: root.ring / 2
                        radiusX: root.ring / 2 - 6
                        radiusY: root.ring / 2 - 6
                        startAngle: -90
                        sweepAngle: 360 * root.fraction
                    }
                }
            }
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.clockText
                    color: Theme.text
                    font.family: Theme.displayFont
                    font.pixelSize: Math.max(18, root.ring * 0.24)
                    font.weight: Font.Light
                    font.features: { "tnum": 1 }
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.label.toUpperCase()
                    color: root.tint
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 10
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Button { icon: "restart_alt"; tip: "Start over"; onClicked: Desktop.focusReset() }
                Button { big: true; icon: Desktop.focusRunning ? "pause" : "play_arrow"; tip: Desktop.focusRunning ? "Pause" : "Start"; onClicked: Desktop.focusToggle() }
                Button { icon: "skip_next"; tip: Desktop.focusMode === "focus" ? "Skip to the break" : "Skip the break"; onClicked: Desktop.focusSkip() }
            }
            Row {
                Layout.alignment: Qt.AlignHCenter
                visible: root.wide || root.height > 300
                spacing: 6
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        width: 10
                        height: 10
                        radius: 5
                        color: index < Desktop.focusRounds % 4 ? Theme.accent : Qt.alpha(Theme.text, 0.15)
                    }
                }
            }
        }
    }
}
