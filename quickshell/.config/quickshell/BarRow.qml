import QtQuick
import QtQuick.Layouts

// One section of the bar: its modules in a row. A divider only shows between two shown items,
// so hidden ones (no meeting, not recording) don't leave doubled or dangling lines.
RowLayout {
    id: root
    property var modules: []
    property bool settingsActive: false
    signal action(string name)

    // Something in this section is shown (dividers don't count)
    readonly property bool hasContent: {
        repeater.count;
        for (let i = 0; i < repeater.count; i++) {
            const m = repeater.itemAt(i);
            if (m && m.moduleId !== "divider" && m.wanted)
                return true;
        }
        return false;
    }

    spacing: 12

    // A divider shows when content comes before and after it, and it's the first one since the
    // content before
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

    // The first shown item with one of these ids, or null
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
