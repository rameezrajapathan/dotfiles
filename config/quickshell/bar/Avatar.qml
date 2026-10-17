import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

ClippingRectangle {
    id: root
    property real size: 24

    implicitWidth: size
    implicitHeight: size
    radius: Theme.round(size / 2, width, height)
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
    GlassRim {}
}
