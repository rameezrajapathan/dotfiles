import Quickshell
import QtQuick

Label {
    id: root
    signal clicked()

    SystemClock {
        id: clock
        precision: Settings.bar.seconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    // 12 or 24 hours, with or without seconds (Settings app > Bar); on a side bar hours, minutes
    // (and seconds) on lines of their own
    text: Theme.barVertical
        ? (Settings.bar.clock24 ? Qt.formatDateTime(clock.date, "HH") : (clock.date.getHours() + 11) % 12 + 1)
            + Qt.formatDateTime(clock.date, "\nmm" + (Settings.bar.seconds ? "\nss" : ""))
        : Qt.formatDateTime(clock.date, (Settings.bar.clock24 ? "HH:mm" : "h:mm")
            + (Settings.bar.seconds ? ":ss" : "") + (Settings.bar.clock24 ? "" : " AP"))
    horizontalAlignment: Text.AlignHCenter
    lineHeight: Theme.barVertical ? 0.9 : 1
    font.bold: Theme.barVertical

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
