import QtQuick
import QtQuick.Shapes
import qs.config
import qs.modules.theme

Item {
    id: root

    // =========================================================================
    // API Properties
    // =========================================================================

    property real value: 0           // 0.0 to 1.0
    property real startAngleDeg: 180 // 9 o'clock
    property real spanAngleDeg: 180  // Clockwise sweep
    
    property color accentColor: Colors.primary
    property color trackColor: Colors.outline
    
    property real lineWidth: 6
    property real ringPadding: 12    // Padding from edge
    
    property bool enabled: true
    property bool dashed: false      // Enable dashed style for progress
    property bool dashedActive: false// Animate dashes (breathing/marquee)
    
    // Wavy properties kept for compatibility (ignored in Shape version)
    property bool wavy: false
    property real waveAmplitude: 0
    property real waveFrequency: 0

    // =========================================================================
    // Signals
    // =========================================================================

    signal valueEdited(real newValue)
    signal draggingChanged(bool dragging)

    // =========================================================================
    // Internal Logic
    // =========================================================================

    readonly property bool isDragging: mouseArea.isDragging
    property real dragValue: 0
    
    // Handle Animation
    property real animatedHandleOffset: isDragging ? 9 : 6
    property real animatedHandleWidth: isDragging ? lineWidth * 0.5 : lineWidth
    Behavior on animatedHandleOffset { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on animatedHandleWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Dash Configuration (Matches CarouselProgress logic)
    property real dotSize: lineWidth
    property real baseDashLength: dotSize * 2.5
    property real targetSpacing: 6
    
    // Dynamic Dash/Gap
    // Active:   Dash = base, Gap = target
    // Inactive: Dash = base + target, Gap = 0 (Solid)
    
    property real currentDashLen: dashedActive ? baseDashLength : (baseDashLength + targetSpacing)
    property real currentGapLen: dashedActive ? targetSpacing : 0
    
    Behavior on currentDashLen { NumberAnimation { duration: Config.animDuration; easing.type: Easing.InOutQuad } }
    Behavior on currentGapLen { NumberAnimation { duration: Config.animDuration; easing.type: Easing.InOutQuad } }

    // Marquee Animation
    property real phase: 0
    readonly property real cycleLength: baseDashLength + targetSpacing
    
    NumberAnimation on phase {
        running: root.dashedActive && root.visible
        from: 0
        to: -root.cycleLength // Move forward along path
        duration: 1000 // Adjust speed
        loops: Animation.Infinite
    }

    // Geometry Helpers
    readonly property real radius: (Math.min(width, height) / 2) - ringPadding
    readonly property real effectiveValue: isDragging ? dragValue : value
    
    // Handle Position & Gaps
    property real handleSpacing: 10 // Gap in pixels around handle
    
    // Convert pixel gap to angle
    readonly property real gapAngleRad: (handleSpacing / 2) / Math.max(1, radius)
    readonly property real gapAngleDeg: gapAngleRad * 180 / Math.PI
    
    // Current Angle (for Handle)
    readonly property real currentAngleRad: (startAngleDeg + (spanAngleDeg * effectiveValue)) * Math.PI / 180

    // =========================================================================
    // Input Handling
    // =========================================================================

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.enabled
        preventStealing: true
        
        property bool isDragging: false

        function updateValueFromMouse(mouseX, mouseY) {
            let centerX = width / 2;
            let centerY = height / 2;
            let angle = Math.atan2(mouseY - centerY, mouseX - centerX);
            if (angle < 0) angle += 2 * Math.PI;

            let startRad = root.startAngleDeg * Math.PI / 180;
            let spanRad = root.spanAngleDeg * Math.PI / 180;
            
            // Normalize angle relative to start
            let relAngle = angle - startRad;
            while (relAngle < 0) relAngle += 2 * Math.PI;
            
            let progress = 0;
            if (relAngle <= spanRad) {
                progress = relAngle / spanRad;
            } else {
                // Snap to nearest end
                let distToEnd = relAngle - spanRad;
                let distToStart = 2 * Math.PI - relAngle;
                progress = (distToEnd < distToStart) ? 1.0 : 0.0;
            }
            
            root.dragValue = progress;
        }

        onPressed: mouse => {
            isDragging = true;
            root.dragValue = root.value;
            root.draggingChanged(true);
            updateValueFromMouse(mouse.x, mouse.y);
        }

        onPositionChanged: mouse => {
            if (isDragging) updateValueFromMouse(mouse.x, mouse.y);
        }

        onReleased: {
            if (isDragging) {
                isDragging = false;
                root.draggingChanged(false);
                root.valueEdited(root.dragValue);
            }
        }
    }

    // =========================================================================
    // Rendering (QtQuick.Shapes)
    // =========================================================================

    Shape {
        id: shapeRenderer
        anchors.fill: parent
        // layer.enabled removed to prevent rasterization pixelation
        preferredRendererType: Shape.CurveRenderer

        // 1. Progress Arc (Dashed or Solid)
        // From start to (current - gap)
        ShapePath {
            strokeColor: root.accentColor
            strokeWidth: root.lineWidth
            
            strokeStyle: root.dashed ? ShapePath.DashLine : ShapePath.SolidLine
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            
            // Dash Logic
            dashPattern: [
                Math.max(0.001, root.currentDashLen / root.lineWidth),
                Math.max(0.001, root.currentGapLen / root.lineWidth)
            ]
            dashOffset: root.phase / root.lineWidth
            
            fillColor: "transparent"
            
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                
                startAngle: root.startAngleDeg
                
                // Sweep up to handle gap
                // Total span done: span * value
                // Subtract gap
                // If result is negative, arc is invisible
                sweepAngle: Math.max(0, (root.spanAngleDeg * root.effectiveValue) - root.gapAngleDeg)
            }
        }

        // 2. Track (Background) - Always Solid
        // From (current + gap) to end
        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.lineWidth
            strokeStyle: ShapePath.SolidLine
            capStyle: ShapePath.RoundCap
            
            fillColor: "transparent"
            
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                
                // Start after handle gap
                startAngle: root.startAngleDeg + (root.spanAngleDeg * root.effectiveValue) + root.gapAngleDeg
                
                // Sweep remainder
                // Total span remaining: span * (1 - value)
                // Subtract gap
                sweepAngle: Math.max(0, (root.spanAngleDeg * (1.0 - root.effectiveValue)) - root.gapAngleDeg)
            }
        }
        
        // 3. Handle (Line)
        ShapePath {
            strokeColor: Colors.overBackground
            strokeWidth: root.animatedHandleWidth
            strokeStyle: ShapePath.SolidLine
            capStyle: ShapePath.RoundCap
            
            fillColor: "transparent"
            
            // Line points
            // Start: radius - offset
            // End: radius + offset
            
            startX: (root.width / 2) + (root.radius - root.animatedHandleOffset) * Math.cos(root.currentAngleRad)
            startY: (root.height / 2) + (root.radius - root.animatedHandleOffset) * Math.sin(root.currentAngleRad)
            
            PathLine {
                x: (root.width / 2) + (root.radius + root.animatedHandleOffset) * Math.cos(root.currentAngleRad)
                y: (root.height / 2) + (root.radius + root.animatedHandleOffset) * Math.sin(root.currentAngleRad)
            }
        }
    }
}
