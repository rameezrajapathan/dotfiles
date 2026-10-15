import Quickshell
import QtQuick

Label {
    id: root
    signal clicked()

    SystemClock {
        id: clock
        precision: Settings.bar.seconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    // 12 or 24 hours, with or without seconds (Settings app > Bar)
    text: Qt.formatDateTime(clock.date, (Settings.bar.clock24 ? "HH:mm" : "h:mm")
        + (Settings.bar.seconds ? ":ss" : "") + (Settings.bar.clock24 ? "" : " AP"))

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
