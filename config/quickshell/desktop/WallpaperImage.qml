import Quickshell
import QtQuick
import qs.services

Item {
    id: root
    readonly property string source: Wallpaper.url
    readonly property real dpr: QsWindow.window?.screen?.devicePixelRatio ?? 1
    readonly property size pixels: Qt.size(Math.ceil(width * dpr), Math.ceil(height * dpr))
    property Image shown: null

    function load() {
        if (shown && shown.source == source)
            return;
        const next = shown === a ? b : a;
        next.source = source;
    }

    onSourceChanged: load()
    Component.onCompleted: load()

    component Layer: Image {
        id: layer
        property bool shrink: false
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: shrink ? root.pixels : Qt.size(-1, -1)
        asynchronous: true
        cache: false
        smooth: true
        opacity: root.shown === layer ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(400); easing.type: Easing.OutCubic } }
        onSourceChanged: shrink = false
        onStatusChanged: {
            if (status !== Image.Ready || source != root.source)
                return;
            if (!shrink && (implicitWidth > root.pixels.width * 1.1 && implicitHeight > root.pixels.height * 1.1)) {
                shrink = true;
                return;
            }
            root.shown = layer;
        }
        onVisibleChanged: if (!visible && root.shown !== layer) source = ""
    }

    Layer { id: a }
    Layer { id: b }
}
