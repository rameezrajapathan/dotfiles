import QtQuick

// Settings app > Sound: the control center's audio panel (outputs, inputs, app volumes).
SettingsPage {
    id: root
    title: "Sound"
    subtitle: "Speakers, microphones and the volume of each app."

    SettingsPanelCard {
        AudioPanel { shown: root.shown }
    }
}
