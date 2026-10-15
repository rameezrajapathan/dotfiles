import QtQuick
import QtQuick.Layouts

// One setting: an icon tile, a title and description, and its control on the right
// (put it inside). With `below: true` the control gets the full width under the text.
Item {
    id: root
    property string icon
    // An app's icon (desktop entry Icon=) instead of a Material Symbol
    property string appIcon
    property string title
    property string description
    property bool below: false
    property bool separator: true
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + 24

    Rectangle {
        // Line above every row but the first
        visible: root.separator && root.parent && root.parent.children[0] !== root
        anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 62; rightMargin: 16 }
        height: 1
        color: Qt.alpha(Theme.overlay, 0.25)
    }

    GridLayout {
        id: layout
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: 14
        anchors.rightMargin: 16
        columns: root.below ? 2 : 3
        columnSpacing: 14
        rowSpacing: 12

        Rectangle {
            visible: root.icon !== "" || root.appIcon !== ""
            Layout.alignment: Qt.AlignTop
            implicitWidth: 34
            implicitHeight: 34
            radius: 11
            color: root.appIcon ? "transparent" : Qt.alpha(Theme.accent, 0.16)

            Icon {
                visible: root.icon !== ""
                anchors.centerIn: parent
                name: root.icon
                size: 19
                color: Theme.accent
            }
            AppIcon {
                visible: root.appIcon !== ""
                anchors.centerIn: parent
                icon: root.appIcon
                implicitSize: 30
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Label {
                Layout.fillWidth: true
                text: root.title
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Label {
                visible: root.description !== ""
                Layout.fillWidth: true
                text: root.description
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 2
                wrapMode: Text.WordWrap
            }
        }

        Item {
            id: slot
            Layout.column: root.below ? 1 : 2
            Layout.row: root.below ? 1 : 0
            Layout.fillWidth: root.below
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            implicitWidth: children.length ? children[0].implicitWidth : 0
            implicitHeight: children.length ? children[0].implicitHeight : 0

            // The control fills the slot when it's below the text
            Binding {
                when: root.below && slot.children.length > 0
                target: slot.children[0] ?? null
                property: "width"
                value: slot.width
            }
        }
    }
}
