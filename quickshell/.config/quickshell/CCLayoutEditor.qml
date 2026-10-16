import QtQuick
import QtQuick.Layouts

// Settings > Control center: the widgets in each column. Arrows reorder a widget or move it to
// the next column, × removes it; the chips below add one to the chosen column. Any change makes
// the layout Custom (CCStyles.edit).
ColumnLayout {
    id: root
    readonly property var columns: CCStyles.current
    readonly property var used: [].concat(...columns)
    property int target: 0
    readonly property int safeTarget: Math.min(target, columns.length - 1)

    spacing: 12

    function move(c, index, delta) {
        CCStyles.edit(cols => {
            const l = cols[c];
            const j = index + delta;
            if (j >= 0 && j < l.length)
                [l[index], l[j]] = [l[j], l[index]];
        });
    }
    function shift(c, index, delta) {
        CCStyles.edit(cols => {
            const to = cols[c + delta];
            if (!to)
                return;
            const [id] = cols[c].splice(index, 1);
            if (delta > 0)
                to.unshift(id);
            else
                to.push(id);
        });
    }
    function remove(c, index) {
        CCStyles.edit(cols => cols[c].splice(index, 1));
    }
    function add(id) {
        CCStyles.edit(cols => cols[root.safeTarget].push(id));
    }
    // Fewer columns: the widgets of the dropped ones go to the last column kept
    function setCount(n) {
        CCStyles.edit(cols => {
            while (cols.length < n)
                cols.push([]);
            while (cols.length > n)
                cols[n - 1].push(...cols.pop());
        });
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Label {
            Layout.fillWidth: true
            text: "Columns"
            color: Theme.subtext
        }
        SettingsSegmented {
            options: [{ value: 1, label: "One" }, { value: 2, label: "Two" }, { value: 3, label: "Three" }]
            current: root.columns.length
            onPicked: v => root.setCount(v)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Repeater {
            model: root.columns

            Rectangle {
                id: column
                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                implicitHeight: content.implicitHeight + 16
                radius: 14
                color: Qt.alpha(Theme.base, 0.45)
                border.width: root.safeTarget === index ? 1.5 : 0
                border.color: Qt.alpha(Theme.accent, 0.7)

                // Clicking a column makes it where new widgets go
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.target = column.index
                }

                ColumnLayout {
                    id: content
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                    spacing: 4

                    Label {
                        Layout.leftMargin: 6
                        Layout.bottomMargin: 2
                        text: root.columns.length === 1 ? "Widgets" : "Column " + (column.index + 1)
                        color: Theme.accent
                        font.bold: true
                        font.pixelSize: Theme.fontSize - 1
                    }

                    Label {
                        visible: column.modelData.length === 0
                        Layout.margins: 6
                        text: "Empty"
                        color: Theme.overlay
                        font.pixelSize: Theme.fontSize - 2
                    }

                    Repeater {
                        model: column.modelData

                        Rectangle {
                            id: item
                            required property string modelData
                            required property int index
                            readonly property var info: CCStyles.widget(modelData)

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
                                        onClicked: root.shift(column.index, item.index, -1)
                                    }
                                    BarIconButton {
                                        icon: "keyboard_arrow_up"; size: 16
                                        visible: item.index > 0
                                        onClicked: root.move(column.index, item.index, -1)
                                    }
                                    BarIconButton {
                                        icon: "keyboard_arrow_down"; size: 16
                                        visible: item.index < column.modelData.length - 1
                                        onClicked: root.move(column.index, item.index, 1)
                                    }
                                    BarIconButton {
                                        icon: "chevron_right"; size: 16
                                        visible: column.index < root.columns.length - 1
                                        onClicked: root.shift(column.index, item.index, 1)
                                    }
                                    BarIconButton {
                                        icon: "close"; size: 16
                                        color: Theme.red
                                        onClicked: root.remove(column.index, item.index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        visible: root.columns.length > 1
        spacing: 10
        Label {
            text: "Add to"
            color: Theme.subtext
        }
        SettingsSegmented {
            options: root.columns.map((c, i) => ({ value: i, label: "Column " + (i + 1) }))
            current: root.safeTarget
            onPicked: v => root.target = v
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: CCStyles.widgets.filter(w => !root.used.includes(w.id))

            CCAddChip {
                required property var modelData
                icon: modelData.icon
                text: modelData.label
                onClicked: root.add(modelData.id)
            }
        }
    }
}
