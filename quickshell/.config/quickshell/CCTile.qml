import QtQuick
import QtQuick.Layouts

// A quick tile. Large: icon, label and state in a row, with an arrow on the right that opens
// the details (`more`) when `hasMore`. Small: a square with the icon on top and the label below;
// right click opens the details. Accent colored while `active`.
Rectangle {
    id: root
    property string icon
    property string label
    property string detail
    // Small tiles' text, when the label is too long or the state says more (the network's name)
    property string shortLabel: ""
    property bool active: false
    property bool hasMore: false
    property bool small: false
    signal clicked()
    signal more()

    readonly property color fg: active ? Theme.accentText : Theme.text

    implicitHeight: small ? 76 : 64
    radius: 20
    color: active ? (mainMouse.containsMouse ? Qt.lighter(Theme.accent, 1.06) : Theme.accent)
        : mainMouse.containsMouse ? Qt.alpha(Theme.surface, 0.85) : Qt.alpha(Theme.surface, 0.55)
    Behavior on color { ColorAnimation { duration: Theme.ms(150) } }

    MouseArea {
        id: mainMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? (root.hasMore && root.more()) : root.clicked()
    }

    // Large
    RowLayout {
        visible: !root.small
        anchors.fill: parent
        anchors.leftMargin: 16
        spacing: 12

        Icon {
            name: root.icon
            filled: root.active
            size: 22
            color: root.fg
            Behavior on color { ColorAnimation { duration: Theme.ms(150) } }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label {
                Layout.fillWidth: true
                text: root.label
                color: root.fg
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.detail
                color: root.active ? Qt.alpha(Theme.accentText, 0.75) : Theme.subtext
                font.pixelSize: Theme.fontSize - 2
                elide: Text.ElideRight
            }
        }
        // Details arrow, split off by a thin line
        Item {
            visible: root.hasMore
            Layout.fillHeight: true
            implicitWidth: 42

            Rectangle {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 1
                height: parent.height - 24
                color: root.active ? Qt.alpha(Theme.accentText, 0.2) : Qt.alpha(Theme.overlay, 0.3)
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 14
                color: moreMouse.containsMouse ? Qt.alpha(root.active ? Theme.accentText : Theme.text, 0.1) : "transparent"
            }
            Icon {
                anchors.centerIn: parent
                name: "chevron_right"
                color: root.fg
            }
            MouseArea {
                id: moreMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.more()
            }
        }
        Item {
            visible: !root.hasMore
            implicitWidth: 4
        }
    }

    // Small
    Item {
        visible: root.small
        anchors.fill: parent
        anchors.margins: 12

        Icon {
            anchors { left: parent.left; top: parent.top }
            name: root.icon
            filled: root.active
            size: 22
            color: root.fg
        }
        Icon {
            visible: root.hasMore
            anchors { right: parent.right; top: parent.top; topMargin: -4; rightMargin: -4 }
            name: "chevron_right"
            size: 18
            color: Qt.alpha(root.fg, moreSmall.containsMouse ? 1 : 0.55)

            MouseArea {
                id: moreSmall
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.more()
            }
        }
        Label {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            text: root.shortLabel || root.label
            color: root.fg
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }
}
