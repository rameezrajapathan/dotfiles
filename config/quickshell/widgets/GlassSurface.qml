import Quickshell
import QtQuick
import qs.services

Item {
    id: root
    default property alias shape: holder.data
    property color tint: Theme.baseTranslucent
    property real band: 14
    property real rim: Glass.rim
    property real refraction: Glass.refraction
    property bool lens: true
    property bool shadow: true
    property real shadowSpread: 22
    property point shadowOffset: Qt.point(0, 8)
    property bool tracking: false
    property string backdropSource: Glass.wallpaper
    property Item backdropItem: null
    property bool fill: backdropItem !== null
    readonly property bool shaderReady: effect.status !== ShaderEffect.Error
    readonly property color solid: shaderReady ? "white" : Qt.rgba(tint.r, tint.g, tint.b, 1)
    readonly property real pad: shadow && Glass.shadows ? shadowSpread + Math.max(Math.abs(shadowOffset.x), Math.abs(shadowOffset.y)) : 2

    property vector4d backdropA: Qt.vector4d(0, 0, 0, 0)
    property vector4d backdropB: Qt.vector4d(0, 0, 0, 0)
    property point itemLight: Glass.lightDir
    property bool mapped: false

    function windowOrigin() {
        const w = QsWindow.window;
        if (!w || !w.screen || w.anchors === undefined)
            return null;
        const s = w.screen;
        const a = w.anchors;
        const m = w.margins;
        const x = a.left ? m.left : a.right ? s.width - w.width - m.right : (s.width - w.width) / 2;
        const y = a.top ? m.top : a.bottom ? s.height - w.height - m.bottom : (s.height - w.height) / 2;
        return { x: x, y: y, sw: s.width, sh: s.height };
    }

    function updateMap() {
        const o = backdropItem ? { x: 0, y: 0, sw: backdropItem.width, sh: backdropItem.height } : windowOrigin();
        if (!o || o.sw <= 0 || wall.status !== Image.Ready || wall.implicitWidth <= 0 || !visible) {
            mapped = false;
            return;
        }
        const iw = wall.implicitWidth;
        const ih = wall.implicitHeight;
        const scale = Math.max(o.sw / iw, o.sh / ih);
        const cu = o.sw / (iw * scale);
        const cv = o.sh / (ih * scale);
        const toUv = p => Qt.point((1 - cu) / 2 + (o.x + p.x) / o.sw * cu, (1 - cv) / 2 + (o.y + p.y) / o.sh * cv);
        const target = backdropItem ?? null;
        const p0 = effect.mapToItem(target, 0, 0);
        const px = effect.mapToItem(target, effect.width, 0);
        const py = effect.mapToItem(target, 0, effect.height);
        const u0 = toUv(p0);
        const ux = toUv(px);
        const uy = toUv(py);
        backdropA = Qt.vector4d(u0.x, u0.y, ux.x - u0.x, ux.y - u0.y);
        backdropB = Qt.vector4d(uy.x - u0.x, uy.y - u0.y, 0, 0);
        const ax = Qt.point(px.x - p0.x, px.y - p0.y);
        const ay = Qt.point(py.x - p0.x, py.y - p0.y);
        const lx = Math.hypot(ax.x, ax.y) || 1;
        const ly = Math.hypot(ay.x, ay.y) || 1;
        const L = Glass.lightDir;
        itemLight = Qt.point((ax.x * L.x + ax.y * L.y) / lx, (ay.x * L.x + ay.y * L.y) / ly);
        mapped = true;
    }

    onXChanged: updateMap()
    onYChanged: updateMap()
    onWidthChanged: updateMap()
    onHeightChanged: updateMap()
    onVisibleChanged: updateMap()
    Component.onCompleted: updateMap()

    Connections {
        target: Glass
        function onLightDirChanged() { root.updateMap(); }
    }

    FrameAnimation {
        running: root.tracking && root.visible && root.lens && (Glass.refraction > 0 || root.fill)
        onTriggered: root.updateMap()
    }

    Image {
        id: wall
        visible: false
        source: root.lens && (Glass.refraction > 0 || root.fill) ? root.backdropSource : ""
        sourceSize.width: 480
        asynchronous: true
        cache: true
        smooth: true
        onStatusChanged: root.updateMap()
    }

    Item {
        id: holder
        width: root.width
        height: root.height
        opacity: root.shaderReady ? 1 : root.tint.a
    }

    ShaderEffectSource {
        id: shapeTex
        sourceItem: holder
        hideSource: root.shaderReady
        sourceRect: Qt.rect(-root.pad, -root.pad, root.width + 2 * root.pad, root.height + 2 * root.pad)
        visible: false
    }

    ShaderEffect {
        id: effect
        x: -root.pad
        y: -root.pad
        width: root.width + 2 * root.pad
        height: root.height + 2 * root.pad
        visible: root.shaderReady
        fragmentShader: Qt.resolvedUrl("../shaders/glass.frag.qsb")

        property var shape: shapeTex
        property var backdrop: wall
        property size size: Qt.size(width, height)
        property size backdropSize: Qt.size(wall.implicitWidth, wall.implicitHeight)
        property vector4d backdropA: root.backdropA
        property vector4d backdropB: root.backdropB
        property color tint: root.tint
        property color rimColor: Glass.rimColor
        property color shadowColor: root.shadow && Glass.shadows ? Glass.shadowColor : "transparent"
        property point lightDir: root.itemLight
        property point shadowOffset: root.shadowOffset
        property real band: root.band
        property real rim: root.rim
        property real refraction: root.refraction
        property real chroma: Glass.chroma
        property real lens: root.lens && root.mapped && wall.status === Image.Ready ? 1 : 0
        property real shadowSpread: root.shadow && Glass.shadows ? root.shadowSpread : 0
        property real fill: root.fill ? 1 : 0
    }
}
