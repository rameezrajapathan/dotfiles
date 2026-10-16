import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Notifications"
    subtitle: "Popups, and when to keep quiet."

    readonly property var n: Settings.notifications

    function validTime(t) {
        return /^([01]?\d|2[0-3]):[0-5]\d$/.test(t.trim());
    }

    SettingsSection {
        title: "Do Not Disturb"
        subtitle: NotificationService.scheduledQuiet ? "Quiet hours are on right now." : ""

        SettingsRow {
            icon: "do_not_disturb_on"
            title: "Do Not Disturb"
            description: "Notifications still go to the list; only critical ones pop up."
            Switch {
                checked: NotificationService.dnd
                onToggled: NotificationService.dnd = !checked
            }
        }
        SettingsRow {
            icon: "schedule"
            title: "Quiet hours"
            description: "Every day between two times."
            Switch {
                checked: root.n.schedule
                onToggled: root.n.schedule = !checked
            }
        }
        SettingsRow {
            visible: root.n.schedule
            icon: "bedtime"
            title: "From – to"
            description: "24-hour times, e.g. 22:00 and 07:00."
            Row {
                spacing: 8
                SettingsTextField {
                    implicitWidth: 90
                    text: root.n.from
                    onAccepted: t => { if (root.validTime(t)) root.n.from = t.trim(); }
                }
                Label { text: "–"; anchors.verticalCenter: parent.verticalCenter; color: Theme.subtext }
                SettingsTextField {
                    implicitWidth: 90
                    text: root.n.to
                    onAccepted: t => { if (root.validTime(t)) root.n.to = t.trim(); }
                }
            }
        }
    }

    SettingsSection {
        title: "Popups"
        canReset: root.n.position !== "top-right" || root.n.timeout !== 6 || !root.n.appTimeout || root.n.maxPopups !== 5 || root.n.width !== 400
        onReset: {
            root.n.position = "top-right";
            root.n.timeout = 6;
            root.n.appTimeout = true;
            root.n.maxPopups = 5;
            root.n.width = 400;
        }

        SettingsRow {
            icon: "picture_in_picture"
            title: "Position"
            below: true
            SettingsChips {
                options: [
                    { value: "top-left", label: "Top left" },
                    { value: "top", label: "Top" },
                    { value: "top-right", label: "Top right" },
                    { value: "bottom-left", label: "Bottom left" },
                    { value: "bottom-right", label: "Bottom right" }
                ]
                current: root.n.position
                onPicked: v => root.n.position = v
            }
        }
        SettingsRow {
            icon: "timer"
            title: "Show for"
            SettingsSlider {
                from: 2; to: 20
                value: root.n.timeout
                suffix: " s"
                onMoved: v => root.n.timeout = v
            }
        }
        SettingsRow {
            icon: "apps"
            title: "Let apps choose how long"
            description: "Use an app's own timeout when it sets one."
            Switch {
                checked: root.n.appTimeout
                onToggled: root.n.appTimeout = !checked
            }
        }
        SettingsRow {
            icon: "stacks"
            title: "At most on screen"
            SettingsSlider {
                from: 1; to: 8
                value: root.n.maxPopups
                onMoved: v => root.n.maxPopups = v
            }
        }
        SettingsRow {
            icon: "width"
            title: "Width"
            SettingsSlider {
                from: 320; to: 560; stepSize: 20
                value: root.n.width
                suffix: " px"
                onMoved: v => root.n.width = v
            }
        }
        SettingsRow {
            icon: "notifications_active"
            title: "Try it"
            description: "Sends a test notification."
            Pill {
                icon: "send"
                implicitHeight: 30
                onClicked: Quickshell.execDetached(["notify-send", "-a", "Settings", "-i", "preferences-desktop", "Hello from Settings", "This is how notifications look now."])
            }
        }
    }
}
