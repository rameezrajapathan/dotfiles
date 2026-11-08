import QtQuick
import qs.services

NumberAnimation {
    property string motion
    readonly property var motionInfo: PanelMotion.info(motion)

    duration: PanelMotion.openDuration(motion)
    easing.type: motionInfo.easing
    easing.overshoot: PanelMotion.overshootOf(motionInfo)
}
