import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.widgets

ClippingRectangle {
    id: root
    implicitHeight: 190
    radius: Theme.round(16, width, height)
    color: Theme.surface

    Image {
        id: wall
        anchors.fill: parent
        source: Glass.wallpaper
        sourceSize.width: 960
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    GlassSurface {
        id: pill
        x: (root.width - width) / 2
        y: 14
        width: Math.min(360, root.width - 40)
        height: 34
        backdropItem: wall
        lens: Glass.active
        shadow: false
        band: 11

        Rectangle {
            width: pill.width
            height: pill.height
            radius: Theme.round(17, width, height)
            color: pill.solid
        }
    }

    GlassSurface {
        id: card
        x: (root.width - width) / 2
        y: 62
        width: Math.min(300, root.width - 60)
        height: 108
        backdropItem: wall
        lens: Glass.active
        tint: Theme.denseTranslucent
        shadowSpread: 14
        shadowOffset: Qt.point(0, 5)

        Rectangle {
            width: card.width
            height: card.height
            radius: Theme.round(22, width, height)
            color: card.solid
        }
    }

    ColumnLayout {
        anchors.centerIn: card
        spacing: 2
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Glass.active ? Glass.labels[Glass.preset] : "Glass is off"
            color: Theme.text
            font.family: Theme.displayFont
            font.pixelSize: Theme.fontSize + 6
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: !Glass.active ? (Toggles.gameMode ? "Game mode turns glass off" : "Plain translucent panels, wallpaper colors") : "Rim " + Math.round(Glass.rim * 100) + "% · Refraction " + Math.round(Glass.refraction * 100) + "%"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 2
        }
    }

    Row {
        anchors.centerIn: pill
        spacing: 8
        Repeater {
            model: 5
            Rectangle {
                required property int index
                width: index === 2 ? 22 : 8
                height: 8
                radius: 4
                color: index === 2 ? Theme.selectedFill : Qt.alpha(Theme.text, 0.5)
            }
        }
    }
}
