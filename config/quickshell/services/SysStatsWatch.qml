import QtQuick

QtObject {
    id: root

    property bool active: true
    property bool held: false

    function sync() {
        if (active === held)
            return;
        held = active;
        SysStats.watch(active);
    }

    onActiveChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (held) SysStats.watch(false)
}
