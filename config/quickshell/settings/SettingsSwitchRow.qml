import QtQuick
import qs.services
import qs.widgets

SettingsRow {
    id: root
    property var target: null
    property string key
    property string hypr
    property bool fallback: false
    readonly property bool on: hypr ? !!(Hypr.value(hypr) ?? fallback) : !!(target?.[key])
    signal switched(bool value)

    function set(value) {
        if (hypr)
            Hypr.set(hypr, value);
        else if (target)
            target[key] = value;
        switched(value);
    }

    Switch {
        checked: root.on
        onToggled: root.set(!root.on)
    }
}
