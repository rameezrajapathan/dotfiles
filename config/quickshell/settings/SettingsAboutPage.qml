import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "About"
    subtitle: "pikadots — a minimal Hyprland + Quickshell desktop."

    property var info: ({})

    onShownChanged: if (shown) reader.running = true

    Process {
        id: reader
        command: ["sh", "-c", ". /etc/os-release; echo \"os=$PRETTY_NAME\"; echo \"kernel=$(uname -r)\"; "
            + "echo \"host=$(cat /etc/hostname 2>/dev/null || uname -n)\"; echo \"hyprland=$(hyprctl version -j | jq -r .version)\"; "
            + "echo \"quickshell=$(qs --version | sed 's/ (.*//; s/Quickshell //')\"; "
            + "echo \"cpu=$(sed -n 's/^model name\\s*: //p' /proc/cpuinfo | head -1)\"; "
            + "echo \"memory=$(awk '/MemTotal/ { printf \"%.0f GB\", $2 / 1048576 }' /proc/meminfo)\"; "
            + "echo \"uptime=$(uptime -p | sed 's/^up //')\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        out[line.slice(0, i)] = line.slice(i + 1);
                }
                root.info = out;
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 120
        radius: Theme.round(20, width, height)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.35) }
            GradientStop { position: 1; color: Qt.alpha(Theme.surface, 0.45) }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.pad(24, 20, parent.width, parent.height)
            spacing: 20

            Avatar {
                size: 72
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: User.displayName
                    color: Theme.text
                    font.family: Theme.displayFont
                    font.pixelSize: 24
                    font.weight: Font.Bold
                }
                Label {
                    text: (root.info.host ?? "") + (root.info.os ? "  ·  " + root.info.os : "")
                    color: Theme.subtext
                }
                Label {
                    visible: !!root.info.uptime
                    text: "Up " + (root.info.uptime ?? "")
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }
    }

    SettingsSection {
        title: "System"

        Repeater {
            model: [
                { key: "cpu", icon: "memory", title: "Processor" },
                { key: "memory", icon: "memory_alt", title: "Memory" },
                { key: "kernel", icon: "terminal", title: "Kernel" },
                { key: "hyprland", icon: "window", title: "Hyprland" },
                { key: "quickshell", icon: "widgets", title: "Quickshell" }
            ]
            SettingsRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.title
                Label {
                    text: root.info[modelData.key] ?? "…"
                    color: Theme.subtext
                    elide: Text.ElideLeft
                }
            }
        }
    }

    SettingsSection {
        title: "Settings file"

        SettingsRow {
            icon: "description"
            title: Settings.path.replace(Quickshell.env("HOME"), "~")
            description: "Your choices live here, outside the dotfiles repo."
            Pill {
                icon: "open_in_new"
                tip: "Edit in a text editor"
                implicitHeight: 30
                onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/app.sh", "editor", Settings.path])
            }
        }
    }
}
