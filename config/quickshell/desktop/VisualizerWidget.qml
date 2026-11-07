import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true

    readonly property bool playing: Cava.active && Cava.levels.length > 0
    readonly property bool reflect: height > 150
    readonly property bool titled: height > 150 && Media.active !== null
    readonly property int count: Math.max(8, Math.min(Cava.barCount, Math.floor((width - 32) / 13)))
    readonly property var levels: Cava.grouped(count)
    readonly property real gap: Math.max(3, Math.round((width - 32) / count * 0.28))
    readonly property real bar: ((width - 32) - gap * (count - 1)) / count
    readonly property real floor: titled ? height - 26 - (reflect ? (height - 60) * 0.28 : 0) : reflect ? height * 0.66 : height - 16
    readonly property real reach: floor - (titled ? 58 : 16)

    property real breath: 0
    SequentialAnimation on breath {
        running: root.live && !root.playing && !Theme.reduceMotion
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 1600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 1600; easing.type: Easing.InOutSine }
    }

    ColumnLayout {
        visible: root.titled
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 0
        Label {
            Layout.fillWidth: true
            text: Media.active?.trackTitle || Media.active?.identity || ""
            font.weight: Font.Bold
            elide: Text.ElideRight
        }
        Label {
            Layout.fillWidth: true
            text: Media.active?.trackArtist ?? ""
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 1
            elide: Text.ElideRight
        }
    }

    Repeater {
        model: root.count
        Item {
            id: column
            required property int index
            readonly property real wave: Math.sin(index / root.count * Math.PI * 2 + root.breath * Math.PI) * 0.5 + 0.5
            readonly property real level: root.playing ? Math.pow(root.levels[index] ?? 0, 0.75) : 0.04 + 0.06 * wave
            readonly property real tall: Math.max(root.bar, level * root.reach)
            readonly property color tint: Theme.mix(Theme.accents[0], Theme.multiColor ? Theme.accents[1] : Theme.accentEnd, root.count > 1 ? index / (root.count - 1) : 0)
            x: 16 + index * (root.bar + root.gap)
            width: root.bar
            height: root.height

            Rectangle {
                y: root.floor - column.tall
                width: root.bar
                height: column.tall
                radius: Theme.round(root.bar / 2, width, height)
                color: column.tint
                opacity: root.playing ? 0.55 + 0.45 * column.level : 0.35
                Behavior on height { NumberAnimation { duration: Theme.ms(70) } }
                Behavior on y { NumberAnimation { duration: Theme.ms(70) } }
            }
            Rectangle {
                visible: root.reflect
                y: root.floor + 4
                width: root.bar
                height: column.tall * 0.35
                radius: Theme.round(root.bar / 2, width, height)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(column.tint, 0.28) }
                    GradientStop { position: 1; color: Qt.alpha(column.tint, 0) }
                }
                Behavior on height { NumberAnimation { duration: Theme.ms(70) } }
            }
        }
    }

    Label {
        visible: !root.playing && root.height > 110
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 14 }
        text: Media.active ? "Paused" : "Play some music"
        color: Theme.overlay
        font.pixelSize: Theme.fontSize - 1
    }

    MouseArea {
        anchors.fill: parent
        visible: Media.active !== null
        cursorShape: Qt.PointingHandCursor
        onClicked: Media.active.togglePlaying()
    }
}
