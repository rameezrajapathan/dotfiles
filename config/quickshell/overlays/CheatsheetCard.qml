import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: card
    required property var modelData

    width: parent.width
    implicitHeight: cardContent.implicitHeight + 32
    radius: Theme.round(18, width, height)
    color: Theme.baseTranslucent
    border.width: Glass.active ? 0 : 1
    border.color: Qt.alpha(Theme.text, 0.08)

    MouseArea {
        anchors.fill: parent
    }

    ColumnLayout {
        id: cardContent
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(16, 18, parent.width, parent.height) }
        spacing: 8

        RowLayout {
            Layout.bottomMargin: 4
            spacing: 10

            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: Theme.round(10, width, height)
                color: Qt.alpha(Theme.accent, 0.18)

                Icon {
                    anchors.centerIn: parent
                    name: card.modelData.icon
                    filled: true
                    color: Theme.accent
                }
            }
            Label {
                text: card.modelData.title
                font.bold: true
                font.pixelSize: Theme.fontSize + 2
            }
        }

        Repeater {
            model: card.modelData.rows

            RowLayout {
                id: bindRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 12

                Label {
                    Layout.fillWidth: true
                    text: bindRow.modelData.desc
                    color: Theme.subtext
                    elide: Text.ElideRight
                }

                Row {
                    spacing: 4

                    Repeater {
                        model: bindRow.modelData.keys

                        Rectangle {
                            required property string modelData
                            implicitWidth: Math.max(26, keyLabel.implicitWidth + 14)
                            implicitHeight: 24
                            radius: Theme.round(7, width, height)
                            color: Qt.alpha(Theme.surface, 0.9)
                            border.width: Glass.active ? 0 : 1
                            border.color: Qt.alpha(Theme.text, 0.12)

                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
                                height: 3
                                radius: Theme.round(6, width, height)
                                color: Qt.alpha(Theme.base, 0.5)
                                GlassRim {}
                            }

                            Label {
                                id: keyLabel
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -1
                                text: parent.modelData
                                color: parent.modelData === "Super" ? Theme.accent : Theme.text
                                font.pixelSize: Theme.fontSize - 2
                                font.bold: true
                            }
                            GlassRim {}
                        }
                    }
                }
            }
        }
    }
    GlassRim {}
}
