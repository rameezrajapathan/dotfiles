import QtQuick
import QtQuick.Layouts
import qs.services

GridLayout {
    id: root
    property var cc
    property bool small: false

    columns: small ? 3 : 2
    rowSpacing: 8
    columnSpacing: 8

    readonly property var shownTiles: Settings.controlCenter.tiles.filter(id => CCTileMap.shown(id))

    Repeater {
        model: root.shownTiles

        CCTile {
            required property string modelData
            readonly property var tileInfo: CCTileMap.info(modelData)

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            small: root.small
            icon: tileInfo.icon
            label: tileInfo.label
            shortLabel: tileInfo.short ?? ""
            compactLabel: tileInfo.compact ?? ""
            detail: tileInfo.detail
            active: tileInfo.active
            hasMore: tileInfo.more !== ""
            onClicked: CCTileMap.act(modelData, root.cc)
            onMore: root.cc.openDetail(tileInfo.more)
        }
    }
}
