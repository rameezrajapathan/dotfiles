import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Updates"
    subtitle: Updates.checking ? "Checking…" : Updates.checked ? "Last checked " + Updates.ago(Updates.checked) + "." : "Not checked yet."

    readonly property var repo: Updates.pikadots
    readonly property var sys: Updates.system

    onShownChanged: if (shown) Updates.checkIfOld()
    Component.onCompleted: Updates.checkIfOld()

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: summary.implicitHeight + 36
        radius: Theme.round(18, width, height)
        color: Qt.alpha(Updates.count > 0 ? Theme.accent : Theme.green, 0.12)

        RowLayout {
            id: summary
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.pad(20, 18, parent.width, parent.height) }
            spacing: 16

            Rectangle {
                implicitWidth: 52
                implicitHeight: 52
                radius: Theme.round(16, width, height)
                color: Updates.count > 0 ? Theme.accent : Qt.alpha(Theme.green, 0.25)
                Icon {
                    anchors.centerIn: parent
                    name: Updates.checking ? "progress_activity" : Updates.count > 0 ? "download" : "verified"
                    size: 26
                    color: Updates.count > 0 ? Theme.accentText : Theme.green
                    RotationAnimation on rotation {
                        running: Updates.checking
                        from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                        onRunningChanged: if (!running) parent.rotation = 0
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: Updates.checking && !Updates.checked ? "Checking for updates"
                        : Updates.count > 0 ? Updates.count + " update" + (Updates.count === 1 ? "" : "s") + " available"
                        : "Everything is up to date"
                    color: Theme.text
                    font.family: Theme.displayFont
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }
                Label {
                    Layout.fillWidth: true
                    text: [Updates.behind > 0 ? "pikadots " + Updates.behind : "",
                           Updates.systemCount > 0 ? "packages " + Updates.systemCount : ""].filter(s => s).join(" · ") || "pikadots and system packages"
                    color: Theme.subtext
                }
            }
            Pill {
                text: Updates.checking ? "Checking…" : "Check now"
                implicitHeight: 32
                onClicked: Updates.check()
            }
        }
    }

    SettingsSection {
        title: "pikadots"

        SettingsRow {
            icon: "commit"
            title: root.repo ? root.repo.branch + " · " + root.repo.commit : "pikadots"
            description: root.repo ? (root.repo.subject + " · " + root.repo.date) : "Not checked yet"
            Pill {
                text: Updates.behind > 0 ? "Update" : "Repair"
                active: Updates.behind > 0
                implicitHeight: 32
                onClicked: Updates.behind > 0 ? Updates.updatePikadots() : Updates.repairPikadots()
            }
        }
        SettingsRow {
            visible: (root.repo?.error ?? "") !== ""
            icon: "cloud_off"
            title: root.repo?.error ?? ""
            description: "Showing the last known state."
        }
        SettingsRow {
            visible: (root.repo?.dirty ?? 0) > 0
            icon: "edit_note"
            title: root.repo?.dirty + " local change" + (root.repo?.dirty === 1 ? "" : "s")
            description: "Your own edits in " + (root.repo?.path ?? "") + " are set aside while updating and put back afterwards."
        }
        SettingsRow {
            visible: (root.repo?.ahead ?? 0) > 0
            icon: "upload"
            title: root.repo?.ahead + " commit" + (root.repo?.ahead === 1 ? "" : "s") + " not pushed"
            description: "Only on this computer."
        }
        SettingsRow {
            visible: Updates.behind > 0
            icon: "auto_awesome"
            title: "What's new"
            below: true
            ColumnLayout {
                spacing: 4
                Repeater {
                    model: root.repo?.incoming ?? []
                    RowLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        spacing: 10
                        Label {
                            text: modelData.split(" ")[0]
                            color: Theme.accent
                            font.family: Settings.appearance.monoFont
                            font.pixelSize: Theme.fontSize - 1
                        }
                        Label {
                            Layout.fillWidth: true
                            text: modelData.slice(modelData.indexOf(" ") + 1)
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    SettingsSection {
        visible: Settings.updates.system
        title: "System"

        SettingsRow {
            icon: "deployed_code_update"
            title: Updates.systemCount > 0 ? Updates.systemCount + " package update" + (Updates.systemCount === 1 ? "" : "s") : "Packages are up to date"
            description: root.sys ? [(root.sys.manager || "Arch") + " " + root.sys.packages.length, (root.sys.helper ? "AUR " : "") + (root.sys.helper ? root.sys.aur.length : ""),
                                     "Flatpak " + root.sys.flatpak.length].filter(s => s.trim()).join(" · ")
                : "Not checked yet"
            Pill {
                text: "Update system"
                active: Updates.systemCount > 0
                implicitHeight: 32
                onClicked: Updates.updateSystem()
            }
        }
        SettingsRow {
            visible: Updates.systemCount > 0
            icon: "list"
            title: "Packages"
            below: true
            Flow {
                spacing: 6
                Repeater {
                    model: root.sys ? root.sys.packages.concat(root.sys.aur, root.sys.flatpak).slice(0, 60) : []
                    Rectangle {
                        required property string modelData
                        implicitWidth: pkg.implicitWidth + 18
                        implicitHeight: 26
                        radius: Theme.round(13, width, height)
                        color: Qt.alpha(Theme.base, 0.6)
                        Label {
                            id: pkg
                            anchors.centerIn: parent
                            text: { const p = modelData.split(/\s+/); return p[0] + (p.length > 1 ? " " + p[p.length - 1] : ""); }
                            font.pixelSize: Theme.fontSize - 2
                        }
                        GlassRim {}
                    }
                }
            }
        }
    }

    SettingsSection {
        title: "Checking"

        SettingsRow {
            icon: "update"
            title: "Check for updates"
            SettingsSegmented {
                options: [
                    { value: 0, label: "Manually" },
                    { value: 1, label: "Hourly" },
                    { value: 6, label: "6 hours" },
                    { value: 24, label: "Daily" }
                ]
                current: Settings.updates.checkHours
                onPicked: v => Settings.updates.checkHours = v
            }
        }
        SettingsRow {
            icon: "notifications"
            title: "Notify me"
            description: "When pikadots or many packages have updates."
            Switch {
                checked: Settings.updates.notify
                onToggled: Settings.updates.notify = !checked
            }
        }
        SettingsRow {
            icon: "inventory_2"
            title: "Include system packages"
            description: "System packages (pacman and AUR, or dnf) and Flatpak. Off: only pikadots."
            Switch {
                checked: Settings.updates.system
                onToggled: Settings.updates.system = !checked
            }
        }
    }
}
