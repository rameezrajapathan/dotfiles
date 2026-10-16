import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Weather"
    subtitle: "Forecasts from Open-Meteo."

    property string query: ""

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
                checked: BarStyles.has("weather")
                onToggled: BarStyles.toggle("weather", !checked, "clock")
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
                onToggled: Weather.setAutoLocation(!checked)
            }
        }
        SettingsRow {
            icon: "search"
            title: "Choose a city"
            below: true
            ColumnLayout {
                spacing: 4
                SettingsTextField {
                    id: cityField
                    Layout.fillWidth: true
                    placeholder: "Type a city"
                    onEdited: t => {
                        root.query = t;
                        searchTimer.restart();
                    }
                    onAccepted: t => {
                        searchTimer.stop();
                        Weather.search(t);
                    }
                }
                Timer {
                    id: searchTimer
                    interval: 400
                    onTriggered: Weather.search(root.query)
                }
                Label {
                    visible: text !== ""
                    Layout.leftMargin: 4
                    text: Weather.searching ? "Searching…"
                        : root.query.trim().length >= 2 && Weather.results.length === 0 ? "No places found" : ""
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 2
                }
                Repeater {
                    model: Weather.results
                    Rectangle {
                        id: result
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: Theme.round(10, width, height)
                        color: resultMouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.pad(10, 10, parent.width, parent.height)
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
                            onClicked: {
                                Weather.choose(result.modelData);
                                cityField.clear();
                                root.query = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
