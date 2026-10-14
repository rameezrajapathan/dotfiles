import Quickshell
import QtQuick

Label {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd d MMM   HH:mm")
}
