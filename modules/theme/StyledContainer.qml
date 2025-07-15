import QtQuick
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    color: Colors.surface
    radius: 16
    border.color: Colors.surfaceBright
    border.width: 0

    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 0
        radius: 8
        samples: 16
        color: Qt.rgba(Colors.shadow.r, Colors.shadow.g, Colors.shadow.b, 0.5)
        transparentBorder: true
    }
}
