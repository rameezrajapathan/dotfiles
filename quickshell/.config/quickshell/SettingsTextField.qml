import QtQuick
import QtQuick.Layouts

// One-line text input; `accepted` fires on Enter or when focus leaves with a changed value,
// `edited` on every change.
Rectangle {
    id: root
    property string text
    property string placeholder
    // What's typed now (text is only the starting value)
    readonly property alias currentText: input.text
    signal accepted(string text)
    // Every keystroke, for live filters
    signal edited(string text)
    // Enter only (not focus leaving)
    signal entered(string text)

    function clear() {
        input.text = "";
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitWidth: 240
    implicitHeight: 34
    radius: 10
    color: Qt.alpha(Theme.base, 0.6)
    border.width: input.activeFocus ? 1 : 0
    border.color: Theme.accent

    // Focus on a click anywhere in the field (the input itself is only one line high)
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: mouse => {
            input.forceActiveFocus();
            mouse.accepted = false;
        }
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        text: root.text
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText
        clip: true
        onTextChanged: root.edited(text)
        onAccepted: {
            root.entered(text);
            root.accepted(text);
            focus = false;
        }
        onActiveFocusChanged: if (!activeFocus && text !== root.text) root.accepted(text)
        Keys.onEscapePressed: {
            text = root.text;
            focus = false;
        }

        Label {
            visible: !input.text && !input.activeFocus
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.overlay
        }
    }
}
