import Quickshell.Widgets
import QtQuick

// The user's profile picture in a circle; the account icon when there is none.
ClippingRectangle {
    id: root
    property real size: 24

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: picture.status === Image.Ready ? "transparent" : Theme.surface

    Image {
        id: picture
        anchors.fill: parent
        source: User.avatar
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
        smooth: true
        mipmap: true
    }

    Icon {
        visible: picture.status !== Image.Ready
        anchors.centerIn: parent
        name: "person"
        filled: true
        size: root.size * 0.65
        color: Theme.subtext
    }
}
