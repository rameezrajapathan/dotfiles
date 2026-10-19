import QtQuick
import QtQuick.Layouts
import qs.services

GridLayout {
    id: root
    property var modules: []
    property real along: 0
    readonly property bool vertical: Theme.barVertical
    readonly property real length: vertical ? implicitHeight : implicitWidth
    property bool settingsActive: false
    signal action(string name)

    readonly property bool hasContent: {
        repeater.count;
        for (let i = 0; i < repeater.count; i++) {
            const m = repeater.itemAt(i);
            if (m && m.moduleId !== "divider" && m.wanted)
                return true;
        }
        return false;
    }

    flow: vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
    rowSpacing: vertical ? 10 : 0
    columnSpacing: vertical ? 0 : 12
    x: vertical ? Theme.barCrossStart + (Theme.pillHeight - width) / 2 : along
    y: vertical ? along : Theme.barCrossStart + (Theme.pillHeight - height) / 2

    function dividerShown(index) {
        let before = false;
        for (let i = index - 1; i >= 0; i--) {
            const m = repeater.itemAt(i);
            if (!m || !m.wanted)
                continue;
            if (m.moduleId === "divider")
                return false;
            before = true;
            break;
        }
        if (!before)
            return false;
        for (let i = index + 1; i < repeater.count; i++) {
            const m = repeater.itemAt(i);
            if (m && m.wanted && m.moduleId !== "divider")
                return true;
        }
        return false;
    }

    function find(ids) {
        for (const id of ids) {
            for (let i = 0; i < repeater.count; i++) {
                const m = repeater.itemAt(i);
                if (m && m.moduleId === id && m.visible)
                    return m;
            }
        }
        return null;
    }

    Repeater {
        id: repeater
        model: root.modules

        BarModule {
            required property string modelData
            required property int index
            moduleId: modelData
            settingsActive: root.settingsActive
            dividerShown: {
                repeater.count;
                return moduleId === "divider" && root.dividerShown(index);
            }
            onAction: name => root.action(name)
        }
    }
}
