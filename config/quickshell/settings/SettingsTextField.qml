import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    property string text
    property string placeholder
    property string icon: ""
    property bool secret: false
    property bool search: false
    property bool commitOnBlur: !search
    property real cornerRadius: 10
    property real inset: 12
    property color fill: Qt.alpha(Theme.base, 0.6)
    readonly property alias currentText: input.text
    readonly property alias inputFocused: input.activeFocus
    signal accepted(string text)
    signal edited(string text)
    signal stepped(int delta)
    signal escaped()

    function clear() {
        input.text = "";
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitWidth: 240
    implicitHeight: 34
    radius: Theme.round(cornerRadius, width, height)
    color: fill
    border.width: input.activeFocus ? 1 : 0
    border.color: Theme.gradientAccent && (input.activeFocus) ? "transparent" : Theme.accent
    GradientBorder {
        active: input.activeFocus
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: mouse => {
            input.forceActiveFocus();
            mouse.accepted = false;
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.pad(root.inset, root.cornerRadius, parent.width, parent.height)
        anchors.rightMargin: Theme.pad(root.inset, root.cornerRadius, parent.width, parent.height)
        spacing: 8

        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: 18
            color: Theme.subtext
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: TextInput.AlignVCenter
            text: root.text
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            clip: true
            echoMode: root.secret ? TextInput.Password : TextInput.Normal
            onTextChanged: root.edited(text)
            onAccepted: {
                root.accepted(text);
                if (!root.search)
                    focus = false;
            }
            onActiveFocusChanged: if (!activeFocus && root.commitOnBlur && text !== root.text) root.accepted(text)
            Keys.onEscapePressed: {
                if (root.search) {
                    root.escaped();
                    return;
                }
                text = root.text;
                focus = false;
            }
            Keys.onUpPressed: event => {
                if (root.search)
                    root.stepped(-1);
                else
                    event.accepted = false;
            }
            Keys.onDownPressed: event => {
                if (root.search)
                    root.stepped(1);
                else
                    event.accepted = false;
            }

            Label {
                visible: !input.text && (root.search || !input.activeFocus)
                anchors.verticalCenter: parent.verticalCenter
                text: root.placeholder
                color: Theme.overlay
            }
        }
    }
    GlassRim {}
}
