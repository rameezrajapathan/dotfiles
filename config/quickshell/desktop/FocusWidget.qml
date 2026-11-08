import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services
import qs.widgets

DesktopWidgetContent {
    id: root

    readonly property bool wide: width > height * 1.4
    readonly property real ring: Math.min(wide ? height - 36 : width - 40, wide ? width * 0.45 : height - 96)
    readonly property real fraction: FocusTimer.fraction
    readonly property color tint: FocusTimer.mode === "focus" ? Theme.accent : Theme.green
    readonly property string label: FocusTimer.mode === "focus" ? "Focus" : FocusTimer.mode === "long" ? "Long break" : "Break"
    readonly property string clockText: TimeDate.clock(FocusTimer.left)

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
                IconButton { icon: "restart_alt"; filled: true; tip: "Start over"; onClicked: FocusTimer.reset() }
                IconButton {
                    implicitWidth: 46
                    implicitHeight: 46
                    tone: "accent"
                    fill: root.tint
                    icon: FocusTimer.running ? "pause" : "play_arrow"
                    iconSize: 26
                    filled: true
                    tip: FocusTimer.running ? "Pause" : "Start"
                    onClicked: FocusTimer.toggle()
                }
                IconButton { icon: "skip_next"; filled: true; tip: FocusTimer.mode === "focus" ? "Skip to the break" : "Skip the break"; onClicked: FocusTimer.skip() }
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
                        color: index < FocusTimer.rounds % 4 ? Theme.accent : Qt.alpha(Theme.text, 0.15)
                    }
                }
            }
        }
    }
}
