import QtQuick

Item {
    id: root
    required property var theme
    property Component rim: null
    property string icon
    property string text
    property string label
    property bool confirm: false
    property bool armed: false
    signal activated()

    implicitWidth: text !== "" ? content.implicitWidth + 32 : 48
    implicitHeight: 48

    Timer {
        id: disarm
        interval: 4000
        onTriggered: root.armed = false
    }

    Rectangle {
        id: circle
        anchors.fill: parent
        radius: root.theme.round(height / 2, width, height)
        color: root.armed ? Qt.alpha(root.theme.red, 0.9)
            : mouse.containsMouse ? Qt.alpha(root.theme.surface, 0.85) : Qt.alpha(root.theme.base, 0.45)
        border.width: 1
        border.color: Qt.alpha(root.theme.text, root.armed ? 0 : 0.12)
        scale: mouse.pressed ? 0.92 : 1
        Behavior on color { ColorAnimation { duration: root.theme.ms(160) } }
        Behavior on scale { NumberAnimation { duration: root.theme.ms(120); easing.type: Easing.OutCubic } }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 8

            LockIcon {
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                name: root.icon
                size: 22
                color: root.armed ? root.theme.base : root.theme.text
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.text !== ""
                text: root.text
                color: root.theme.text
                font.family: root.theme.displayFont
                font.weight: Font.Medium
                font.pixelSize: 14
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 10
        width: tip.implicitWidth + 20
        height: 28
        radius: root.theme.round(14, width, height)
        color: Qt.alpha(root.theme.base, 0.8)
        opacity: root.label !== "" && (mouse.containsMouse || root.armed) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.theme.ms(150) } }

        Text {
            id: tip
            anchors.centerIn: parent
            text: root.armed ? "Click again to " + root.label.toLowerCase() : root.label
            font.family: root.theme.displayFont
            font.pixelSize: root.theme.fontSize
            color: root.armed ? root.theme.red : root.theme.text
        }
        Loader {
            anchors.fill: parent
            sourceComponent: root.rim
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.confirm && !root.armed) {
                root.armed = true;
                disarm.restart();
                return;
            }
            root.armed = false;
            root.activated();
        }
    }
}
