import QtQuick
import QtQuick.Shapes
import qs.config
import qs.modules.theme

Item {
    id: root

    // =========================================================================
    // API Properties (Compatible with original CarouselProgress)
    // =========================================================================
    
    property color color: Styling.srItem("overprimary")
    property real dotSize: 4
    property real spacing: 6 // This maps to gap size
    property real speed: 10 // Pixels per second
    property bool running: true
    property bool active: true
    property real targetSpacing: 6 // Target gap when active

    // Compatibility dummies (from old implementation)
    property real lineWidth: dotSize
    property real frequency: 0
    property real amplitudeMultiplier: 0
    property real fullLength: 0
    property bool animationsEnabled: true

    // =========================================================================
    // Internal Logic
    // =========================================================================

    // Dimensions
    readonly property real baseDashLength: dotSize * 2.5
    readonly property real cycleLength: baseDashLength + targetSpacing

    // Dynamic Dash/Gap Configuration
    // Active:   Dash = base, Gap = target
    // Inactive: Dash = base + target, Gap = 0 (Effectively solid line)
    
    // We bind these to local properties to allow animation
    property real currentDashLen: active ? baseDashLength : cycleLength
    property real currentGapLen: active ? targetSpacing : 0

    Behavior on currentDashLen {
        enabled: Config.animDuration > 0
        NumberAnimation { duration: Config.animDuration; easing.type: Easing.InOutQuad }
    }

    Behavior on currentGapLen {
        enabled: Config.animDuration > 0
        NumberAnimation { duration: Config.animDuration; easing.type: Easing.InOutQuad }
    }

    // Animation Phase (Marquee effect)
    property real phase: 0

    NumberAnimation on phase {
        running: root.running && root.visible && root.animationsEnabled
        from: 0
        to: -root.cycleLength // Negative moves right (forward along path)
        duration: (root.cycleLength / Math.max(1, root.speed)) * 1000
        loops: Animation.Infinite
    }

    // =========================================================================
    // Rendering (QtQuick.Shapes)
    // =========================================================================

    Shape {
        anchors.fill: parent
        // layer.enabled removed to prevent rasterization pixelation
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.dotSize
            strokeStyle: ShapePath.DashLine
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            // dashPattern takes values relative to strokeWidth
            dashPattern: [
                Math.max(0.001, root.currentDashLen / root.dotSize),
                Math.max(0.001, root.currentGapLen / root.dotSize)
            ]

            // dashOffset is also relative to strokeWidth
            dashOffset: root.phase / root.dotSize

            startX: -root.dotSize * 2
            startY: root.height / 2
            PathLine { x: root.width + root.dotSize * 2; y: root.height / 2 }
        }
    }
}
