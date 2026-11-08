import QtQuick
import qs.services

Item {
    id: root
    required property var app
    required property SettingsSearch search
    property bool compact: false
    readonly property int count: pageRepeater.count

    function pageAt(i) {
        return pageRepeater.itemAt(i);
    }

    Repeater {
        id: pageRepeater
        model: root.app.pages

        Flickable {
            id: flick
            readonly property Item page: loader.item
            required property var modelData
            readonly property bool current: root.app.page === modelData.key
            property bool visited: false
            onCurrentChanged: if (current) visited = true
            Component.onCompleted: visited = current
            Connections {
                target: root.search
                function onActiveChanged() {
                    if (root.search.active)
                        flick.visited = true;
                }
            }

            anchors.fill: parent
            opacity: current ? 1 : 0
            visible: opacity > 0
            transform: Translate {
                y: flick.current ? 0 : 12
                Behavior on y { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutQuint } }
            }
            Behavior on opacity { NumberAnimation { duration: Theme.ms(flick.current ? 220 : 70) } }
            clip: true
            contentWidth: width
            contentHeight: loader.height + loader.y * 2
            boundsBehavior: Flickable.StopAtBounds

            readonly property int gutter: width < 520 ? 16 : width < 760 ? 24 : 40

            Loader {
                id: loader
                active: flick.visited
                width: Math.min(flick.width - flick.gutter * 2, 880)
                x: Math.max(flick.gutter, (flick.width - width) / 2)
                y: root.compact ? 20 : 36
                height: item?.implicitHeight ?? 0
                source: flick.modelData.source
            }
            Binding {
                target: loader.item
                property: "shown"
                value: flick.current
            }
        }
    }
}
