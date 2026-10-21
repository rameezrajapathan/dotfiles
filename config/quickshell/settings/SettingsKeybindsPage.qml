import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Keybindings"
    subtitle: "Click a shortcut to change it, then press the new keys. Super + ? shows these over your desktop."

    onShownChanged: {
        if (shown)
            Keybinds.refresh();
        else {
            stop();
            confirmEdit = false;
        }
    }
    Component.onDestruction: stop()

    property string filter: ""
    property string recording: ""
    property string message: ""
    property bool confirmEdit: false
    readonly property bool changed: Object.keys(Settings.keybinds).length > 0 || Keybinds.fileState === "modified"
    readonly property var groups: {
        const q = filter.toLowerCase();
        const shown = q === "" ? Keybinds.entries
            : Keybinds.entries.filter(b => b.desc.toLowerCase().includes(q) || b.keys.join(" ").toLowerCase().includes(q));
        return Keybinds.groups
            .map(g => ({ title: g.title, rows: shown.filter(b => b.group === g.title) }))
            .filter(g => g.rows.length > 0);
    }

    function start(id) {
        message = "";
        recording = id;
        Keybinds.record(true);
        catcher.forceActiveFocus();
        timeout.restart();
    }

    function stop() {
        if (recording === "")
            return;
        recording = "";
        timeout.stop();
        Keybinds.record(false);
    }

    function hyprKey(k) {
        if (k >= Qt.Key_A && k <= Qt.Key_Z || k >= Qt.Key_0 && k <= Qt.Key_9)
            return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F24)
            return "F" + (k - Qt.Key_F1 + 1);
        const names = {
            [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return", [Qt.Key_Escape]: "Escape", [Qt.Key_Tab]: "Tab",
            [Qt.Key_Backtab]: "Tab", [Qt.Key_Backspace]: "BackSpace", [Qt.Key_Delete]: "Delete", [Qt.Key_Insert]: "Insert",
            [Qt.Key_Home]: "Home", [Qt.Key_End]: "End", [Qt.Key_PageUp]: "Page_Up", [Qt.Key_PageDown]: "Page_Down",
            [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down",
            [Qt.Key_Space]: "space", [Qt.Key_Print]: "Print",
            [Qt.Key_Minus]: "minus", [Qt.Key_Underscore]: "minus", [Qt.Key_Equal]: "equal", [Qt.Key_Plus]: "equal",
            [Qt.Key_BracketLeft]: "bracketleft", [Qt.Key_BraceLeft]: "bracketleft",
            [Qt.Key_BracketRight]: "bracketright", [Qt.Key_BraceRight]: "bracketright",
            [Qt.Key_Backslash]: "backslash", [Qt.Key_Bar]: "backslash", [Qt.Key_Semicolon]: "semicolon", [Qt.Key_Colon]: "semicolon",
            [Qt.Key_Apostrophe]: "apostrophe", [Qt.Key_QuoteDbl]: "apostrophe", [Qt.Key_Comma]: "comma", [Qt.Key_Less]: "comma",
            [Qt.Key_Period]: "period", [Qt.Key_Greater]: "period", [Qt.Key_Slash]: "slash", [Qt.Key_Question]: "slash",
            [Qt.Key_QuoteLeft]: "grave", [Qt.Key_AsciiTilde]: "grave",
            [Qt.Key_Exclam]: "1", [Qt.Key_At]: "2", [Qt.Key_NumberSign]: "3", [Qt.Key_Dollar]: "4", [Qt.Key_Percent]: "5",
            [Qt.Key_AsciiCircum]: "6", [Qt.Key_Ampersand]: "7", [Qt.Key_Asterisk]: "8", [Qt.Key_ParenLeft]: "9", [Qt.Key_ParenRight]: "0",
            [Qt.Key_VolumeUp]: "XF86AudioRaiseVolume", [Qt.Key_VolumeDown]: "XF86AudioLowerVolume", [Qt.Key_VolumeMute]: "XF86AudioMute",
            [Qt.Key_MicMute]: "XF86AudioMicMute", [Qt.Key_MediaPlay]: "XF86AudioPlay", [Qt.Key_MediaTogglePlayPause]: "XF86AudioPlay",
            [Qt.Key_MediaPause]: "XF86AudioPause", [Qt.Key_MediaNext]: "XF86AudioNext", [Qt.Key_MediaPrevious]: "XF86AudioPrev",
            [Qt.Key_MonBrightnessUp]: "XF86MonBrightnessUp", [Qt.Key_MonBrightnessDown]: "XF86MonBrightnessDown",
            [Qt.Key_KeyboardBrightnessUp]: "XF86KbdBrightnessUp", [Qt.Key_KeyboardBrightnessDown]: "XF86KbdBrightnessDown",
            [Qt.Key_Launch1]: "XF86Launch1"
        };
        return names[k] ?? "";
    }

    function capture(event) {
        if (recording === "") {
            event.accepted = false;
            return;
        }
        event.accepted = true;
        const modOnly = [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_AltGr, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Hyper_L, Qt.Key_Hyper_R, Qt.Key_CapsLock];
        if (modOnly.includes(event.key))
            return;
        const m = event.modifiers;
        const mods = [[Qt.MetaModifier, "SUPER"], [Qt.ControlModifier, "CTRL"], [Qt.AltModifier, "ALT"], [Qt.ShiftModifier, "SHIFT"]]
            .filter(p => m & p[0]).map(p => p[1]);
        if (event.key === Qt.Key_Escape && mods.length === 0) {
            stop();
            return;
        }
        const key = hyprKey(event.key);
        const id = recording;
        stop();
        if (key === "") {
            message = "That key can't be bound here. Edit keybinds.lua for special keys.";
            return;
        }
        const combo = mods.concat([key]).join(" + ");
        const taken = Keybinds.owner(combo, id);
        if (taken) {
            const caps = mods.map(s => s[0] + s.slice(1).toLowerCase()).concat([Keybinds.keyName(key)]);
            message = `${caps.join(" + ")} is already used by “${taken.desc || "a hidden shortcut"}”.`;
            return;
        }
        Keybinds.rebind(id, combo);
    }

    Item {
        id: catcher
        Layout.preferredHeight: 0
        Keys.onPressed: event => root.capture(event)
        onActiveFocusChanged: if (!activeFocus) root.stop()
    }

    Timer {
        id: timeout
        interval: 10000
        onTriggered: root.stop()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        SettingsTextField {
            Layout.fillWidth: true
            placeholder: "Filter by action or key, e.g. screenshot or Shift"
            onEdited: t => root.filter = t
        }
        Pill {
            visible: root.changed
            text: "Reset all"
            implicitHeight: 34
            onClicked: Keybinds.resetAll()
        }
        Pill {
            icon: "edit"
            active: root.confirmEdit
            implicitHeight: 34
            onClicked: root.confirmEdit = !root.confirmEdit
        }
    }

    SettingsSection {
        visible: root.confirmEdit
        title: "Edit the keybind file?"

        SettingsRow {
            icon: "warning"
            title: "Don't edit keybinds.lua unless you know what you're doing"
            description: "A mistake there can break shortcuts or stop Hyprland's config from loading. Changing shortcuts here is safer. To undo your edits, click Reset all on this page or run pikadots keybinds reset; both restore the default file (your edited copy is kept in ~/.local/state/pikadots/backups)."
            below: true

            Row {
                spacing: 8
                Pill {
                    text: "Open anyway"
                    implicitHeight: 32
                    onClicked: {
                        root.confirmEdit = false;
                        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/app.sh", "editor",
                            Quickshell.env("HOME") + "/.config/hypr/keybinds.lua"]);
                    }
                }
                Pill {
                    text: "Cancel"
                    implicitHeight: 32
                    onClicked: root.confirmEdit = false
                }
            }
        }
    }

    Label {
        visible: root.message !== ""
        Layout.fillWidth: true
        text: root.message
        color: Theme.accent
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: root.groups

        SettingsSection {
            id: group
            required property var modelData
            title: modelData.title

            Repeater {
                model: group.modelData.rows

                Item {
                    id: bind
                    required property var modelData
                    readonly property bool active: root.recording !== "" && root.recording === modelData.id
                    Layout.fillWidth: true
                    implicitHeight: 44

                    Label {
                        anchors { left: parent.left; leftMargin: Theme.pad(18, 16); right: reset.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        text: bind.modelData.desc
                        elide: Text.ElideRight
                    }

                    Pill {
                        id: reset
                        visible: bind.modelData.changed
                        icon: "undo"
                        anchors { right: keys.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        onClicked: Keybinds.rebind(bind.modelData.id, "")
                    }

                    Row {
                        id: keys
                        anchors { right: parent.right; rightMargin: Theme.pad(16, 16); verticalCenter: parent.verticalCenter }
                        spacing: 4

                        Repeater {
                            model: bind.active ? ["Press keys · Esc to cancel"] : bind.modelData.keys

                            Rectangle {
                                required property string modelData
                                implicitWidth: Math.max(26, keyLabel.implicitWidth + 14)
                                implicitHeight: 24
                                radius: Theme.round(7, width, height)
                                color: Qt.alpha(Theme.base, 0.7)
                                border.width: bind.active ? 1 : Glass.active ? 0 : 1
                                border.color: bind.active ? Theme.accent : Qt.alpha(Theme.text, 0.12)

                                Label {
                                    id: keyLabel
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    color: bind.active || parent.modelData === "Super" ? Theme.accent : Theme.text
                                    font.pixelSize: Theme.fontSize - 2
                                    font.bold: true
                                }
                                GlassRim {}
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: keys
                        anchors.margins: -4
                        enabled: bind.modelData.editable
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bind.active ? root.stop() : root.start(bind.modelData.id)
                    }
                }
            }
        }
    }
}
