import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// The control center, under the bar's profile picture: widgets in one or more columns, as picked
// on Settings > Control center (CCStyles.qml: "One glance", "Bento" or a custom layout). A tile's
// arrow, a chip or a card opens its details in place (the panels that used to be tabs: account,
// music, notifications, network, Bluetooth, sound, displays, drives, battery, system, capture,
// GitHub), with a back button. Super + S opens it; Esc goes back, then closes; a click outside
// closes. A transparent full-screen overlay.
PanelWindow {
    id: root

    // Closes the other panels when this one opens, and the other way round
    Exclusive { panel: root }
    required property var bar
    // The window stays mapped until the close animation ends
    property bool open: false
    // Details page on screen ("" = the widgets), and the last one, kept while it fades out
    property string detail: ""
    property string shownDetail: ""

    readonly property var details: ({
        account: { title: "Account", page: accountPage },
        music: { title: "Music", page: musicPage },
        notifications: { title: "Notifications", page: notificationsPage },
        network: { title: "Network", page: networkPage },
        bluetooth: { title: "Bluetooth", page: bluetoothPage },
        audio: { title: "Sound", page: audioPage },
        display: { title: "Displays", page: displayPage },
        drives: { title: "Drives", page: drivesPage },
        battery: { title: "Battery", page: batteryPage },
        system: { title: "System", page: systemPage },
        capture: { title: "Capture", page: capturePage },
        github: { title: "GitHub", page: gitHubPage }
    })

    function available(key) {
        switch (key) {
        case "bluetooth": return StatusInfo.btAdapter !== null;
        case "battery": return StatusInfo.battery.isLaptopBattery;
        case "github": return GitHub.signedIn;
        case "drives": return Drives.volumes.length > 0;
        }
        return details[key] !== undefined;
    }

    function openDetail(key) {
        if (!available(key))
            return;
        shownDetail = key;
        detail = key;
    }

    function back() {
        detail = "";
    }

    // Opens on `key`'s details, or the widgets for ""
    function show(key) {
        if (key && available(key))
            openDetail(key);
        else
            detail = "";
        visible = true;
        open = true;
    }

    function close() {
        open = false;
    }

    // A second call for what's already shown closes it
    function toggle(key) {
        if (open && (!key || key === detail))
            close();
        else
            show(key);
    }

    readonly property var columns: CCStyles.current
    readonly property int columnWidth: CCStyles.columnWidth(columns.length)
    readonly property int padding: 16
    readonly property int overviewWidth: columns.length * columnWidth + (columns.length - 1) * 12 + 2 * padding
    // Details pages are as wide as they need, whatever the layout's width
    readonly property int detailWidth: 640
    // Details pages are at least this tall; notifications get room for a long list
    readonly property int detailMinHeight: root.detail === "notifications" ? Math.round(root.maxHeight * 0.8) : 420
    readonly property int maxHeight: Math.min(root.height - Theme.barHeight - 20, 900)

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-controlcenter"
    // Takes the keyboard while open so it works without the mouse; prompts it starts (Wi-Fi
    // password, VPN removal) close it first so they can have the keyboard
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // Drops down from under the bar, like the launcher
    Sheet {
        id: card
        open: root.open
        kind: "settings"
        // Comes out of the details' own bar icon when it's on the bar, else the profile picture
        anchorIds: (root.detail ? (({ audio: ["sound"], music: ["media"], capture: ["capture", "recording"] })[root.detail] ?? [root.detail]) : []).concat(["avatar"])
        sheetWidth: Math.min(root.detail ? root.detailWidth : root.overviewWidth, root.width - 56)
        sheetHeight: Math.min(root.maxHeight, root.detail
            ? Math.max(root.detailMinHeight, (detailLoader.item?.implicitHeight ?? 0) + 52)
            : overview.implicitHeight + 2 * root.padding)
        // Switching between the widgets and a details page reshapes the panel with the same curve
        // it opens with (Settings > Effects > Panels)
        readonly property var motionInfo: PanelMotion.info(motion)
        Behavior on sheetWidth {
            NumberAnimation {
                duration: PanelMotion.openDuration(card.motion)
                easing.type: card.motionInfo.easing
                easing.overshoot: card.motionInfo.overshoot ?? 1.70158
            }
        }
        Behavior on sheetHeight {
            NumberAnimation {
                duration: PanelMotion.openDuration(card.motion)
                easing.type: card.motionInfo.easing
                easing.overshoot: card.motionInfo.overshoot ?? 1.70158
            }
        }
        // More opaque than the bar: it's large and full of text
        color: Qt.alpha(Theme.base, 0.92)
        onClosed: {
            root.visible = false;
            root.detail = "";
        }
        onDismiss: root.close()

        // Clips the content to the sheet's rounded corners
        ClippingRectangle {
            anchors.fill: parent
            radius: card.radius
            color: "transparent"

            Item {
                anchors.fill: parent
                focus: root.open

                // Esc (or Backspace, Alt + Left) goes back from details, then closes
                Keys.onEscapePressed: root.detail ? root.back() : root.close()
                Keys.onPressed: event => {
                    if (root.detail && (event.key === Qt.Key_Backspace || event.key === Qt.Key_Left && event.modifiers & Qt.AltModifier)) {
                        root.back();
                        event.accepted = true;
                    }
                }
            }

            // Widgets
            Flickable {
                id: overviewFlick
                anchors.fill: parent
                opacity: root.detail ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.ms(root.detail ? 90 : 220) } }
                transform: Translate {
                    x: root.detail ? -28 : 0
                    Behavior on x { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutQuint } }
                }
                clip: true
                contentWidth: width
                contentHeight: overview.implicitHeight + 2 * root.padding
                boundsBehavior: Flickable.StopAtBounds

                RowLayout {
                    id: overview
                    x: Math.round((overviewFlick.width - width) / 2)
                    y: root.padding
                    spacing: 12

                    Repeater {
                        model: root.columns

                        ColumnLayout {
                            id: column
                            required property var modelData
                            Layout.preferredWidth: root.columnWidth
                            Layout.fillHeight: true
                            spacing: 12

                            Repeater {
                                model: column.modelData

                                CCWidget {
                                    required property string modelData
                                    widgetId: modelData
                                    cc: root
                                    columns: root.columns.length
                                }
                            }

                            // Keeps the widgets at the top of a column stretched to the tallest one,
                            // unless notifications fill it (CCWidget)
                            Item {
                                visible: root.columns.length < 2 || !column.modelData.includes("notifications")
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }

            // Details
            Item {
                id: detailLayer
                anchors.fill: parent
                opacity: root.detail ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.ms(root.detail ? 220 : 90) } }
                transform: Translate {
                    x: root.detail ? 0 : 28
                    Behavior on x { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutQuint } }
                }

                // The page's own width at most, centered on wide layouts
                readonly property real pageWidth: Math.min(width, 760)

                RowLayout {
                    id: detailHeader
                    x: Math.round((parent.width - detailLayer.pageWidth) / 2) + 12
                    y: 10
                    width: detailLayer.pageWidth - 24
                    spacing: 8

                    CCIconButton {
                        icon: "arrow_back"
                        tone: "flat"
                        onClicked: root.back()
                    }
                    Label {
                        Layout.fillWidth: true
                        text: "Control center"
                        color: Theme.overlay
                        font.pixelSize: Theme.fontSize - 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.back()
                        }
                    }
                }

                Flickable {
                    id: detailFlick
                    x: Math.round((parent.width - detailLayer.pageWidth) / 2)
                    width: detailLayer.pageWidth
                    anchors { top: detailHeader.bottom; bottom: parent.bottom; topMargin: -12 }
                    clip: true
                    contentWidth: width
                    contentHeight: detailLoader.height
                    boundsBehavior: Flickable.StopAtBounds

                    Loader {
                        id: detailLoader
                        width: detailFlick.width
                        height: Math.max(item?.implicitHeight ?? 0, detailFlick.height)
                        active: root.shownDetail !== ""
                        sourceComponent: root.details[root.shownDetail]?.page ?? null
                    }
                    Binding {
                        target: detailLoader.item
                        property: "shown"
                        value: root.open && root.detail !== "" && root.detail === root.shownDetail
                    }
                    Connections {
                        target: detailLoader.item
                        function onCloseRequested() {
                            root.close();
                        }
                    }
                }
            }
        }
    }

    Component { id: musicPage; MediaPanel {} }
    Component { id: notificationsPage; NotificationPanel {} }
    Component { id: networkPage; NetworkPanel {} }
    Component { id: bluetoothPage; BluetoothPanel {} }
    Component { id: audioPage; AudioPanel {} }
    Component { id: displayPage; DisplayPanel {} }
    Component { id: drivesPage; DrivesPanel {} }
    Component { id: batteryPage; BatteryPanel {} }
    Component { id: systemPage; SystemPanel {} }
    Component { id: capturePage; CapturePanel {} }
    Component { id: gitHubPage; GitHubPanel {} }
    Component { id: accountPage; AccountPanel {} }
}
