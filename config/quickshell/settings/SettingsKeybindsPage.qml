import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Keybindings"
    subtitle: "Super + ? shows these over your desktop."

    onShownChanged: if (shown) Keybinds.refresh()

    property string filter: ""
    readonly property var groups: {
        const q = filter.toLowerCase();
        const shown = q === "" ? Keybinds.binds
            : Keybinds.binds.filter(b => b.desc.toLowerCase().includes(q) || b.keys.join(" ").toLowerCase().includes(q));
        return Keybinds.groups
            .map(g => ({ title: g.title, rows: shown.filter(b => b.group === g.title) }))
            .filter(g => g.rows.length > 0);
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        SettingsTextField {
            Layout.fillWidth: true
            placeholder: "Filter by action or key, e.g. screenshot or Shift"
            onEdited: t => root.filter = t
        }
        Pill {
            icon: "edit"
            implicitHeight: 34
            onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/app.sh", "editor",
                Quickshell.env("HOME") + "/.config/hypr/keybinds.lua"])
        }
    }

    Repeater {
        model: root.groups

        SettingsSection {
            id: group
            required property var modelData
            title: modelData.title

            Repeater {
                model: group.modelData.rows

                Item {
                    id: bind
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 44

                    Label {
                        anchors { left: parent.left; leftMargin: 18; right: keys.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        text: bind.modelData.desc
                        elide: Text.ElideRight
                    }

                    Row {
                        id: keys
                        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                        spacing: 4

                        Repeater {
                            model: bind.modelData.keys

                            Rectangle {
                                required property string modelData
                                implicitWidth: Math.max(26, keyLabel.implicitWidth + 14)
                                implicitHeight: 24
                                radius: 7
                                color: Qt.alpha(Theme.base, 0.7)
                                border.width: 1
                                border.color: Qt.alpha(Theme.text, 0.12)

                                Label {
                                    id: keyLabel
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    color: parent.modelData === "Super" ? Theme.accent : Theme.text
                                    font.pixelSize: Theme.fontSize - 2
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
