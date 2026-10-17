import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    property string icon
    property string label
    property string detail
    property string shortLabel: ""
    property string compactLabel: ""
    readonly property bool narrow: width < 200
    property bool active: false
    property bool hasMore: false
    property bool small: false
    signal clicked()
    signal more()

    readonly property color fg: active ? Theme.selectedText : Theme.text

    implicitHeight: small ? 76 : 64
    radius: Theme.round(20, width, height)
    color: active ? (mainMouse.containsMouse ? Qt.lighter(Theme.selectedFill, 1.06) : Theme.selectedFill)
        : Theme.glassFill(2, mainMouse.containsMouse)
    gradient: Theme.accentFill(active)
    Behavior on color { ColorAnimation { duration: Theme.ms(150) } }

    GlassRim {
        strength: root.active ? 0.6 : 1
    }

    MouseArea {
        id: mainMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? (root.hasMore && root.more()) : root.clicked()
    }

    RowLayout {
        visible: !root.small
        anchors.fill: parent
        anchors.leftMargin: Theme.pad(root.narrow ? 12 : 16, 20, parent.width, parent.height)
        spacing: root.narrow ? 9 : 12

        Icon {
            name: root.icon
            filled: root.active
            size: root.narrow ? 20 : 22
            color: root.fg
            Behavior on color { ColorAnimation { duration: Theme.ms(150) } }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label {
                Layout.fillWidth: true
                text: root.narrow && root.compactLabel ? root.compactLabel : root.label
                color: root.fg
                font.weight: Font.DemiBold
                font.pixelSize: root.narrow ? Theme.fontSize - 1 : Theme.fontSize
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.detail
                color: root.active ? Qt.alpha(Theme.selectedText, 0.75) : Theme.subtext
                font.pixelSize: root.narrow ? Theme.fontSize - 3 : Theme.fontSize - 2
                elide: Text.ElideRight
            }
        }
        Item {
            visible: root.hasMore
            Layout.fillHeight: true
            implicitWidth: root.narrow ? 30 : 38

            GlassDivider {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: Glass.active ? 2 : 1
                height: parent.height - 24
                strength: 0.5
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: Theme.round(14, width, height)
                color: moreMouse.containsMouse ? Qt.alpha(root.active ? Theme.selectedText : Theme.text, 0.1) : "transparent"
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

    Item {
        visible: root.small
        anchors.fill: parent
        anchors.margins: Theme.pad(12, 20, parent.width, parent.height)

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
        TextMetrics {
            id: smallMetrics
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.DemiBold
            text: root.shortLabel || root.label
        }
        Label {
            id: smallLabel
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            text: root.compactLabel && smallMetrics.advanceWidth > width ? root.compactLabel : root.shortLabel || root.label
            color: root.fg
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.DemiBold
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Theme.fontSize - 4
            elide: Text.ElideRight
        }
    }
}
