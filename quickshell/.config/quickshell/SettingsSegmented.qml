import QtQuick

// A row of choices with a gliding highlight. options: [{ value, label, icon? }].
Rectangle {
    id: root
    property var options: []
    property var current
    signal picked(var value)

    readonly property int index: options.findIndex(o => o.value === current)

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 34
    radius: height / 2
    color: Qt.alpha(Theme.base, 0.6)

    Rectangle {
        readonly property Item target: {
            repeater.count;
            return repeater.itemAt(root.index);
        }
        visible: target !== null
        x: 4 + (target?.x ?? 0)
        y: 4
        width: target?.width ?? 0
        height: parent.height - 8
        radius: height / 2
        color: Theme.accent
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
    }

    Row {
        id: row
        x: 4
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            id: repeater
            model: root.options

            Item {
                id: option
                required property var modelData
                required property int index
                readonly property bool selected: root.index === index

                implicitWidth: content.implicitWidth + 24
                implicitHeight: root.height - 8

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        visible: !!option.modelData.icon
                        anchors.verticalCenter: parent.verticalCenter
                        name: option.modelData.icon ?? ""
                        size: 16
                        filled: option.selected
                        color: option.selected ? Theme.accentText : Theme.text
                    }
                    Label {
                        visible: text !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: option.modelData.label ?? ""
                        color: option.selected ? Theme.accentText : Theme.text
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: option.selected ? Font.DemiBold : Font.Normal
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(option.modelData.value)
                }
            }
        }
    }
}
