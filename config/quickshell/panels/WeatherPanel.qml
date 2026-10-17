import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services
import qs.widgets

PanelWindow {
    id: root

    Exclusive { panel: root }
    required property var bar

    property bool open: false
    property bool searchOpen: false

    readonly property var now: Weather.current
    readonly property var today: Weather.daily[0] ?? null
    readonly property real weekMin: Math.min(...Weather.daily.map(d => d.min))
    readonly property real weekMax: Math.max(...Weather.daily.map(d => d.max))

    function toggle() {
        if (!open) {
            searchOpen = false;
            Weather.refreshIfStale();
            visible = true;
        }
        open = !open;
    }

    function ago(date) {
        const min = Math.round((clock.date.getTime() - date.getTime()) / 60000);
        return min < 1 ? "just now" : min < 60 ? min + " min ago" : Math.round(min / 60) + " h ago";
    }

    function speed(kmh) {
        return Weather.fahrenheit ? Math.round(kmh * 0.621) + " mph" : Math.round(kmh) + " km/h";
    }

    function nextSun() {
        const t = clock.date.getTime();
        const d0 = Weather.daily[0], d1 = Weather.daily[1];
        if (!d0)
            return { label: "Sunrise", time: "—" };
        if (t < d0.sunrise.getTime())
            return { label: "Sunrise", time: Qt.formatTime(d0.sunrise, "h:mm AP") };
        if (t < d0.sunset.getTime())
            return { label: "Sunset", time: Qt.formatTime(d0.sunset, "h:mm AP") };
        return { label: "Sunrise", time: d1 ? Qt.formatTime(d1.sunrise, "h:mm AP") : "—" };
    }

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-weather"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Sheet {
        id: sheet
        open: root.open
        kind: "weather"
        sheetWidth: 560
        sheetHeight: content.implicitHeight + 40
        onClosed: root.visible = false
        onDismiss: root.open = false

        MouseArea {
            anchors.fill: parent
            onClicked: root.searchOpen = false
        }

        Item {
            focus: root.open
            Keys.onEscapePressed: {
                if (root.searchOpen)
                    root.searchOpen = false;
                else
                    root.open = false;
            }
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(20, 24) }
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    id: placeButton
                    Layout.fillWidth: true
                    implicitHeight: placeRow.implicitHeight

                    Row {
                        id: placeRow
                        spacing: 6

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: Weather.autoLocation ? "near_me" : "pin_drop"
                            filled: Weather.autoLocation
                            size: 16
                            color: Theme.accent
                            gradientFill: true
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.place || "Finding you…"
                            font.bold: true
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Weather.region !== ""
                            text: Weather.region
                            color: Theme.subtext
                        }
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "expand_more"
                            size: 16
                            color: placeMouse.containsMouse || root.searchOpen ? Theme.text : Theme.subtext
                            rotation: root.searchOpen ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: Theme.ms(200) } }
                        }
                    }

                    MouseArea {
                        id: placeMouse
                        width: placeRow.implicitWidth
                        height: parent.height
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.searchOpen = !root.searchOpen;
                            if (root.searchOpen) {
                                searchInput.text = "";
                                Weather.results = [];
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }

                Pill {
                    text: "°C"
                    active: !Weather.fahrenheit
                    onClicked: Weather.setUnit(false)
                }
                Pill {
                    text: "°F"
                    active: Weather.fahrenheit
                    onClicked: Weather.setUnit(true)
                }
                Pill {
                    id: refreshPill
                    icon: "refresh"
                    onClicked: Weather.autoLocation ? Weather.locate() : Weather.refresh()
                    RotationAnimator on rotation {
                        running: Weather.loading
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) refreshPill.rotation = 0
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 14
                visible: root.now !== null
                spacing: 16

                Label {
                    text: root.now ? Weather.temp(root.now.temp) : ""
                    font.pixelSize: 64
                    font.weight: Font.Light
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Label {
                        text: root.now ? Weather.label(root.now.code) : ""
                        font.pixelSize: Theme.fontSize + 3
                        font.bold: true
                    }
                    Label {
                        text: root.now ? "feels like " + Weather.temp(root.now.feels) : ""
                        color: Theme.subtext
                    }
                    Label {
                        text: root.today ? "↑ " + Weather.temp(root.today.max) + "   ↓ " + Weather.temp(root.today.min) : ""
                        color: Theme.subtext
                    }
                }

                Icon {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 6
                    name: root.now ? Weather.icon(root.now.code, root.now.isDay) : ""
                    size: 64
                    weight: 200
                    color: Theme.accent
                    gradientFill: true
                }
            }

            WeatherSection {
                text: "Next hours"
                visible: Weather.hourly.length > 0
            }
            WeatherHourly {
                Layout.fillWidth: true
                visible: Weather.hourly.length > 0
            }

            WeatherSection {
                text: "7 days"
                visible: Weather.ready
            }
            Repeater {
                model: Weather.daily

                RowLayout {
                    id: day
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    spacing: 10

                    Label {
                        Layout.preferredWidth: 52
                        text: day.index === 0 ? "Today" : Qt.formatDate(day.modelData.date, "ddd")
                        color: day.index === 0 ? Theme.text : Theme.subtext
                        font.bold: day.index === 0
                    }
                    Icon {
                        Layout.preferredWidth: 22
                        name: Weather.icon(day.modelData.code, true)
                        size: 18
                        color: Theme.text
                    }
                    Label {
                        Layout.preferredWidth: 36
                        text: day.modelData.precip >= 30 ? day.modelData.precip + "%" : ""
                        color: Theme.accent
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Label {
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                        text: Weather.temp(day.modelData.min)
                        color: Theme.subtext
                    }

                    Item {
                        id: track
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        readonly property real span: Math.max(1, root.weekMax - root.weekMin)

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.round(2, width, height)
                            color: Qt.alpha(Theme.text, 0.08)
                        }
                        Rectangle {
                            x: (day.modelData.min - root.weekMin) / track.span * track.width
                            width: Math.max(4, (day.modelData.max - day.modelData.min) / track.span * track.width)
                            height: parent.height
                            radius: Theme.round(2, width, height)
                            color: Theme.accent
                            gradient: Theme.accentFill(true)
                            opacity: day.index === 0 ? 1 : 0.55
                        }
                        Rectangle {
                            visible: day.index === 0 && root.now !== null
                            x: ((root.now?.temp ?? 0) - root.weekMin) / track.span * track.width - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8
                            height: 8
                            radius: Theme.round(4, width, height)
                            color: Theme.text
                            border.width: 2
                            border.color: Theme.base
                        }
                    }

                    Label {
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                        text: Weather.temp(day.modelData.max)
                    }
                }
            }

            WeatherSection {
                text: "Details"
                visible: Weather.ready
            }
            GridLayout {
                Layout.fillWidth: true
                visible: Weather.ready
                columns: 3
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: [
                        { icon: "humidity_percentage", label: "Humidity", value: (root.now?.humidity ?? 0) + "%" },
                        { icon: "air", label: "Wind " + Weather.compass(root.now?.windDir ?? 0), value: root.speed(root.now?.wind ?? 0) },
                        { icon: "wb_sunny", label: "UV · max " + Math.round(root.today?.uv ?? 0), value: String(Math.round(root.now?.uv ?? 0)) },
                        { icon: "airwave", label: Weather.air ? "Air · " + Weather.aqiLabel(Weather.air.aqi).toLowerCase() : "Air quality", value: Weather.air ? String(Weather.air.aqi) : "—" },
                        { icon: "wb_twilight", label: root.nextSun().label, value: root.nextSun().time },
                        { icon: "compress", label: "Pressure", value: Math.round(root.now?.pressure ?? 0) + " hPa" }
                    ]

                    Rectangle {
                        id: stat
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        radius: Theme.round(12, width, height)
                        color: Qt.alpha(Theme.surface, 0.5)

                        Icon {
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            name: stat.modelData.icon
                            size: 18
                            color: Theme.subtext
                        }
                        Column {
                            x: 40
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Label {
                                text: stat.modelData.value
                                font.bold: true
                            }
                            Label {
                                text: stat.modelData.label
                                color: Theme.subtext
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }
                        GlassRim {}
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.topMargin: 8
                horizontalAlignment: Text.AlignRight
                text: Weather.error !== "" ? Weather.error + " · press refresh"
                    : Weather.ready ? "updated " + root.ago(Weather.updated) + " · open-meteo" : "getting the weather…"
                color: Weather.error !== "" ? Theme.red : Theme.overlay
                font.pixelSize: Theme.fontSize - 3
            }
        }

        Rectangle {
            id: search
            x: content.x
            y: content.y + placeButton.height + 10
            width: 340
            height: searchColumn.implicitHeight + 16
            radius: Theme.round(16, width, height)
            color: Theme.base
            border.width: Glass.active ? 0 : 1
            border.color: Qt.alpha(Theme.text, 0.1)
            opacity: root.searchOpen ? 1 : 0
            scale: root.searchOpen ? 1 : 0.96
            transformOrigin: Item.TopLeft
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }
            Behavior on scale { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.4; shadowBlur: 1; shadowVerticalOffset: 6 }

            MouseArea { anchors.fill: parent }

            Column {
                id: searchColumn
                x: 8
                y: 8
                width: parent.width - 16
                spacing: 4

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: Theme.round(10, width, height)
                    color: Qt.alpha(Theme.surface, 0.7)

                    Icon {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        name: "search"
                        size: 18
                        color: Theme.subtext
                    }
                    TextInput {
                        id: searchInput
                        x: 36
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 46
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        clip: true
                        selectByMouse: true
                        onTextChanged: searchDelay.restart()
                        Keys.onEscapePressed: root.searchOpen = false
                        Keys.onReturnPressed: if (Weather.results.length > 0) { Weather.choose(Weather.results[0]); root.searchOpen = false; }

                        Label {
                            visible: !searchInput.text
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.searching ? "searching…" : "search for a city"
                            color: Theme.subtext
                        }
                    }
                    Timer {
                        id: searchDelay
                        interval: 300
                        onTriggered: Weather.search(searchInput.text)
                    }
                    GlassRim {}
                }

                WeatherSearchRow {
                    icon: "near_me"
                    title: "Use my location"
                    subtitle: "found from your connection"
                    accent: Weather.autoLocation
                    onPicked: {
                        Weather.useMyLocation();
                        root.searchOpen = false;
                    }
                }

                Repeater {
                    model: Weather.results

                    WeatherSearchRow {
                        required property var modelData
                        icon: "pin_drop"
                        title: modelData.name
                        subtitle: [modelData.region, modelData.country].filter(s => s).join(", ")
                        onPicked: {
                            Weather.choose(modelData);
                            root.searchOpen = false;
                        }
                    }
                }
            }
            GlassRim {}
        }
    }
}
