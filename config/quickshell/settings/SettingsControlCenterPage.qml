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
            description: CCStyles.style === "custom" ? "Custom: your own cards and columns."
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

                    SettingsStyleCard {
                        id: card
                        required property var modelData
                        selected: CCStyles.style === modelData.id
                        icon: modelData.icon
                        label: modelData.label
                        onClicked: CCStyles.apply(card.modelData.id)

                        CCPreview {
                            Layout.fillWidth: true
                            implicitHeight: 110
                            columns: card.modelData.columns
                        }
                    }
                }
            }
        }
    }

    SettingsSection {
        title: "Cards"
        subtitle: CCStyles.style === "custom" ? "Click a column, then add cards to it. Hover a card to move or remove it."
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
        subtitle: "Shown by both quick tile cards, in this order. Tiles this machine can't use (Bluetooth without an adapter) hide."

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
