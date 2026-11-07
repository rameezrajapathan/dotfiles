import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true
    property string widgetId: ""
    property bool loaded: false

    FileView {
        id: file
        path: root.widgetId ? Desktop.notesDir + "/" + root.widgetId + ".md" : ""
        printErrors: false
        onLoaded: {
            if (!edit.activeFocus)
                edit.text = text();
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }

    Timer {
        id: saver
        interval: 600
        onTriggered: file.setText(edit.text)
    }

    ColumnLayout {
        anchors { fill: parent; margins: 18 }
        spacing: 8

        RowLayout {
            spacing: 6
            Icon {
                name: "sticky_note_2"
                size: 18
                filled: true
                color: Theme.yellow
            }
            Label {
                Layout.fillWidth: true
                text: "Notes"
                color: Theme.yellow
                font.weight: Font.Bold
            }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: edit.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            HoverHandler {
                cursorShape: Qt.IBeamCursor
            }

            function ensureVisible(r) {
                if (contentY >= r.y)
                    contentY = r.y;
                else if (contentY + height <= r.y + r.height)
                    contentY = r.y + r.height - height;
            }

            TextEdit {
                id: edit
                width: flick.width
                wrapMode: TextEdit.Wrap
                color: Theme.text
                selectionColor: Qt.alpha(Theme.accent, 0.4)
                selectedTextColor: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + (root.size === "small" ? 0 : 1)
                selectByMouse: true
                persistentSelection: true
                onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
                onTextChanged: if (root.loaded && activeFocus) saver.restart()
                onActiveFocusChanged: if (!activeFocus && saver.running) {
                    saver.stop();
                    file.setText(text);
                }
                Keys.onEscapePressed: focus = false

                PointHandler {
                    onActiveChanged: if (active) edit.QsWindow.window?.wantKeyboard?.(edit)
                }

                Label {
                    visible: edit.text === "" && !edit.activeFocus
                    text: "Click to write a note…"
                    color: Theme.overlay
                }
            }
        }
    }

    Component.onDestruction: if (saver.running) file.setText(edit.text)
}
