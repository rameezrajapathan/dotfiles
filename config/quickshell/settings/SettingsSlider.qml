import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

RowLayout {
    id: root
    property real from: 0
    property real to: 1
    property real stepSize: 1
    property real value: 0
    property string suffix: ""
    property int decimals: 0
    signal moved(real value)

    implicitWidth: 260
    spacing: 12

    Slider {
        Layout.fillWidth: true
        value: (root.value - root.from) / (root.to - root.from)
        onMoved: v => {
            const raw = root.from + v * (root.to - root.from);
            const stepped = Math.round(raw / root.stepSize) * root.stepSize;
            const next = Number(Math.max(root.from, Math.min(root.to, stepped)).toFixed(4));
            if (next !== root.value)
                root.moved(next);
        }
    }
    Label {
        Layout.preferredWidth: 46
        horizontalAlignment: Text.AlignRight
        text: root.value.toFixed(root.decimals) + root.suffix
        color: Theme.subtext
        font.features: { "tnum": 1 }
    }
}
