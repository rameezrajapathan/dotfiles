import QtQuick
import QtQuick.Layouts

// Settings app > Weather: units, place (found automatically or searched) and the bar chip.
SettingsPage {
    id: root
    title: "Weather"
    subtitle: "Forecasts from Open-Meteo."

    SettingsSection {
        title: "Display"

        SettingsRow {
            icon: "thermostat"
            title: "Units"
            SettingsSegmented {
                options: [{ value: false, label: "°C" }, { value: true, label: "°F" }]
                current: Weather.fahrenheit
                onPicked: v => Weather.setUnit(v)
            }
        }
        SettingsRow {
            icon: "partly_cloudy_day"
            title: "Show in the bar"
            Switch {
                checked: Settings.bar.weather
                onToggled: Settings.bar.weather = !checked
            }
        }
    }

    SettingsSection {
        title: "Place"

        SettingsRow {
            icon: "pin_drop"
            title: Weather.place || "Not found yet"
            description: Weather.region + (Weather.ready ? "  ·  " + Weather.temp(Weather.current.temp) + ", " + Weather.label(Weather.current.code).toLowerCase() : "")
            Pill {
                icon: "refresh"
                implicitHeight: 30
                onClicked: Weather.refresh()
            }
        }
        SettingsRow {
            icon: "near_me"
            title: "Find my location"
            description: "From your internet connection."
            Switch {
                checked: Weather.autoLocation
                onToggled: { if (!checked) Weather.useMyLocation(); }
            }
        }
        SettingsRow {
            icon: "search"
            title: "Choose a city"
            below: true
            ColumnLayout {
                spacing: 4
                SettingsTextField {
                    Layout.fillWidth: true
                    placeholder: Weather.searching ? "Searching…" : "Type a city and press Enter"
                    onAccepted: t => Weather.search(t)
                }
                Repeater {
                    model: Weather.results
                    Rectangle {
                        id: result
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 10
                        color: resultMouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            spacing: 10
                            Icon { name: "pin_drop"; size: 18; color: Theme.accent }
                            Label { text: result.modelData.name }
                            Label {
                                Layout.fillWidth: true
                                text: [result.modelData.region, result.modelData.country].filter(s => s).join(", ")
                                color: Theme.subtext
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: resultMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Weather.choose(result.modelData)
                        }
                    }
                }
            }
        }
    }
}
