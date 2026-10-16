import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

ColumnLayout {
    id: root
    property string placeholder: "Search a city or region"
    property string current: ""
    property string query: ""
    signal picked(string zone)

    readonly property var results: {
        const words = query.toLowerCase().replace(/[_\/]/g, " ").split(/\s+/).filter(w => w);
        if (words.length === 0)
            return [];
        return TimeDate.zones.filter(z => {
            const name = z.toLowerCase().replace(/[_\/]/g, " ");
            return words.every(w => name.includes(w));
        }).slice(0, 8);
    }

    spacing: 6
    Component.onCompleted: TimeDate.loadZones()

    SettingsTextField {
        id: field
        Layout.fillWidth: true
        placeholder: root.placeholder
        onEdited: t => root.query = t
    }

    Repeater {
        model: root.results

        Rectangle {
            id: row
            required property string modelData
            readonly property bool selected: modelData === root.current

            Layout.fillWidth: true
            implicitHeight: 38
            radius: Theme.round(10, width, height)
            color: selected ? Qt.alpha(Theme.accent, 0.18) : mouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.base, 0.4)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.pad(12, 10, parent.width, parent.height)
                anchors.rightMargin: Theme.pad(12, 10, parent.width, parent.height)
                spacing: 8

                Icon { name: "public"; size: 17; color: Theme.accent }
                Label {
                    text: TimeDate.city(row.modelData)
                    font.weight: Font.DemiBold
                }
                Label {
                    Layout.fillWidth: true
                    text: row.modelData.includes("/") ? row.modelData.slice(0, row.modelData.lastIndexOf("/")).replace(/_/g, " ") : ""
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }
                Icon { visible: row.selected; name: "check"; size: 17; color: Theme.accent }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.picked(row.modelData);
                    field.clear();
                    root.query = "";
                }
            }
        }
    }

    Label {
        visible: root.query !== "" && root.results.length === 0
        text: TimeDate.zones.length ? "No time zone matches" : "Loading time zones…"
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 2
    }
}
