import QtQuick
import QtQuick.Layouts
import qs.services

Loader {
    id: root
    required property string widgetId
    property var cc
    property int columns: 1

    readonly property bool wanted: item ? (item.wanted ?? true) : false
    visible: wanted
    Layout.fillWidth: true
    Layout.fillHeight: widgetId === "notifications" && columns > 1

    sourceComponent: ({
        header: header, tiles: tiles, tilesSmall: tilesSmall, sliders: sliders, media: media,
        mediaLarge: mediaLarge, notifications: notifications, status: status, system: system,
        calendar: calendar, weather: weather, updates: updates, actions: actions, tray: tray
    })[widgetId] ?? null

    Component { id: header; CCHeader { cc: root.cc } }
    Component { id: tiles; CCTiles { cc: root.cc } }
    Component { id: tilesSmall; CCTiles { cc: root.cc; small: true } }
    Component { id: sliders; CCSliders { cc: root.cc; mic: root.columns > 1 } }
    Component { id: media; CCMedia { cc: root.cc } }
    Component { id: mediaLarge; CCMedia { cc: root.cc; large: true } }
    Component { id: notifications; CCNotifications { cc: root.cc; maxItems: root.columns > 1 ? 4 : 2 } }
    Component { id: status; CCStatus { cc: root.cc } }
    Component { id: system; CCSystem { cc: root.cc } }
    Component { id: calendar; CCCalendar { cc: root.cc } }
    Component { id: weather; CCWeather { cc: root.cc } }
    Component { id: updates; CCUpdates { cc: root.cc } }
    Component { id: actions; CCActions { cc: root.cc } }
    Component { id: tray; CCTray { cc: root.cc } }
}
