import QtQuick
import QtQuick.Layouts
import qs.controlcenter
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Control center"
    subtitle: "What opens from your profile picture on the bar (Super + S)."

    SettingsSection {
        title: "Style"

        SettingsRow {
            icon: "dashboard_customize"
            title: "Layout"
            description: CCStyles.style === "custom" ? "Custom: your own widgets and columns."
                : CCStyles.presets.find(p => p.id === CCStyles.style)?.description ?? ""
            below: true

            GridLayout {
                columns: Math.max(1, Math.min(3, Math.floor((width + 10) / 170)))
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: CCStyles.presets.concat([{
                        id: "custom", label: "Custom", icon: "tune",
                        columns: Settings.controlCenter.custom ?? CCStyles.current
                    }])

                    Rectangle {
                        id: card
                        required property var modelData
                        readonly property bool selected: CCStyles.style === modelData.id

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: cardColumn.implicitHeight + 16
                        radius: Theme.round(14, width, height)
                        color: selected ? Qt.alpha(Theme.accent, 0.16) : cardMouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.base, 0.45)
                        border.width: selected ? 2 : 1
                        border.color: Theme.gradientAccent && (selected) ? "transparent" : selected ? Theme.accent : Qt.alpha(Theme.overlay, 0.25)
                        GradientBorder {
                            active: selected
                        }
                        Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

                        ColumnLayout {
                            id: cardColumn
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(8, 14, parent.width, parent.height) }
                            spacing: 8

                            CCPreview {
                                Layout.fillWidth: true
                                implicitHeight: 110
                                columns: card.modelData.columns
                            }
                            RowLayout {
                                Layout.leftMargin: 4
                                Layout.rightMargin: 4
                                spacing: 6
                                Icon {
                                    name: card.modelData.icon
                                    size: 17
                                    filled: card.selected
                                    color: Theme.accent
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: card.modelData.label
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                CheckBadge {
                                    visible: card.selected
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: CCStyles.apply(card.modelData.id)
                        }
                        GlassRim {}
                    }
                }
            }
        }
    }

    SettingsSection {
        title: "Widgets"
        subtitle: CCStyles.style === "custom" ? "Click a column, then add widgets to it. Hover a widget to move or remove it."
            : "Changing anything here makes your own Custom layout, starting from this one."

        Item {
            Layout.fillWidth: true
            implicitHeight: layoutEditor.implicitHeight + 28

            CCLayoutEditor {
                id: layoutEditor
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(14, 16) }
            }
        }
    }

    SettingsSection {
        title: "Quick tiles"
        subtitle: "Shown by both tile widgets, in this order. Tiles this machine can't use (Bluetooth without an adapter) hide."

        Item {
            Layout.fillWidth: true
            implicitHeight: tileEditor.implicitHeight + 28

            CCTileEditor {
                id: tileEditor
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(14, 16) }
            }
        }
    }
}
