import QtQuick
import qs.panels
import qs.services

SettingsPage {
    id: root
    title: "Sound"
    subtitle: "Speakers, microphones and the volume of each app."

    SettingsPanelCard {
        AudioPanel { shown: root.shown }
    }
}
