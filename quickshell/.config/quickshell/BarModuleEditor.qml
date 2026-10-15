import QtQuick
import QtQuick.Layouts

// Settings > Bar: what each section of the bar holds. Arrows reorder an item or move it to the
// next section, × removes it; the chips below add one to the chosen section.
ColumnLayout {
    id: root
    readonly property var keys: ["left", "center", "right"]
    readonly property var titles: Settings.bar.layout === "pill" ? ["Start", "Middle", "End"] : ["Left", "Middle", "Right"]
    property string target: "right"

    readonly property var used: [].concat(Settings.bar.left, Settings.bar.center, Settings.bar.right)

    spacing: 12

    function list(key) {
        return Settings.bar[key].slice();
    }
    function move(key, index, delta) {
        const l = list(key);
        const j = index + delta;
        if (j < 0 || j >= l.length)
            return;
        [l[index], l[j]] = [l[j], l[index]];
        Settings.bar[key] = l;
    }
    // To the start of the section to the right (delta 1) or the end of the one to the left (-1)
    function shift(key, index, delta) {
        const to = keys[keys.indexOf(key) + delta];
        if (!to)
            return;
        const from = list(key);
        const [id] = from.splice(index, 1);
        const dest = list(to);
        if (delta > 0)
            dest.unshift(id);
        else
            dest.push(id);
        Settings.bar[key] = from;
        Settings.bar[to] = dest;
    }
    function remove(key, index) {
        const l = list(key);
        l.splice(index, 1);
        Settings.bar[key] = l;
    }
    function add(id) {
        Settings.bar[target] = list(target).concat([id]);
    }

    Label {
        visible: Settings.bar.layout === "pill"
        Layout.fillWidth: true
        text: "With one pill, the three sections sit side by side in it, a divider between them."
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 2
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Repeater {
            model: root.keys

            Rectangle {
                id: column
                required property string modelData
                required property int index
                readonly property string key: modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                implicitHeight: content.implicitHeight + 16
                radius: 14
                color: Qt.alpha(Theme.base, 0.45)
                border.width: root.target === key ? 1.5 : 0
                border.color: Qt.alpha(Theme.accent, 0.7)

                // Clicking a column makes it where new items go
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.target = column.key
                }

                ColumnLayout {
                    id: content
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.bottomMargin: 2
                        Label {
                            Layout.fillWidth: true
                            text: root.titles[column.index]
                            color: Theme.accent
                            font.bold: true
                            font.pixelSize: Theme.fontSize - 1
                        }
                        Label {
                            text: Settings.bar[column.key].length || ""
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }

                    Label {
                        visible: Settings.bar[column.key].length === 0
                        Layout.fillWidth: true
                        Layout.margins: 6
                        text: "Empty"
                        color: Theme.overlay
                        font.pixelSize: Theme.fontSize - 2
                    }

                    Repeater {
                        model: Settings.bar[column.key]

                        Rectangle {
                            id: item
                            required property string modelData
                            required property int index
                            readonly property var info: BarStyles.module(modelData)
                            readonly property int count: Settings.bar[column.key].length

                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 10
                            color: hover.hovered ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.surface, 0.5)

                            HoverHandler { id: hover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 6
                                spacing: 6

                                Icon { name: item.info.icon; size: 16; color: Theme.accent }
                                Label {
                                    Layout.fillWidth: true
                                    text: item.info.label
                                    elide: Text.ElideRight
                                    font.pixelSize: Theme.fontSize - 1
                                }
                                Row {
                                    visible: hover.hovered
                                    spacing: 2
                                    BarIconButton {
                                        icon: "chevron_left"; size: 16
                                        visible: column.index > 0
                                        onClicked: root.shift(column.key, item.index, -1)
                                    }
                                    BarIconButton {
                                        icon: "keyboard_arrow_up"; size: 16
                                        visible: item.index > 0
                                        onClicked: root.move(column.key, item.index, -1)
                                    }
                                    BarIconButton {
                                        icon: "keyboard_arrow_down"; size: 16
                                        visible: item.index < item.count - 1
                                        onClicked: root.move(column.key, item.index, 1)
                                    }
                                    BarIconButton {
                                        icon: "chevron_right"; size: 16
                                        visible: column.index < 2
                                        onClicked: root.shift(column.key, item.index, 1)
                                    }
                                    BarIconButton {
                                        icon: "close"; size: 16
                                        color: Theme.red
                                        onClicked: root.remove(column.key, item.index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Items not on the bar yet
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 10
        Label {
            text: "Add to"
            color: Theme.subtext
        }
        SettingsSegmented {
            options: root.keys.map((k, i) => ({ value: k, label: root.titles[i] }))
            current: root.target
            onPicked: v => root.target = v
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: BarStyles.modules.filter(m => m.multi || !root.used.includes(m.id))

            Rectangle {
                id: chip
                required property var modelData
                implicitWidth: chipRow.implicitWidth + 22
                implicitHeight: 32
                radius: height / 2
                color: chipMouse.containsMouse ? Qt.alpha(Theme.accent, 0.22) : Qt.alpha(Theme.base, 0.6)
                border.width: 1
                border.color: Qt.alpha(Theme.overlay, 0.3)

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon { name: "add"; size: 15; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Icon { name: chip.modelData.icon; size: 16; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: chip.modelData.label; font.pixelSize: Theme.fontSize - 1; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.add(chip.modelData.id)
                }
            }
        }
    }
}
