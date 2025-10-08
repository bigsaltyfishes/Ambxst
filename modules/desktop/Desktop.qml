import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.desktop
import qs.modules.services
import qs.config

PanelWindow {
    id: desktop

    property int barSize: Config.bar.showBackground ? 44 : 40
    property int bottomTextMargin: 32
    property string barPosition: ["top", "bottom", "left", "right"].includes(Config.bar.position) ? Config.bar.position : "top"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell:desktop"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    visible: Config.desktop.enabled

    Component.onCompleted: {
        DesktopService.maxRowsHint = Qt.binding(() => iconContainer.maxRows);
    }

    Flow {
        id: iconContainer
        anchors.fill: parent
        anchors.margins: 16
        anchors.bottomMargin: desktop.barPosition === "bottom" ? desktop.barSize + 16 : 16
        anchors.topMargin: desktop.barPosition === "top" ? desktop.barSize + 16 : 16
        anchors.leftMargin: desktop.barPosition === "left" ? desktop.barSize + 16 : 16
        anchors.rightMargin: desktop.barPosition === "right" ? desktop.barSize + 16 : 16

        flow: Flow.TopToBottom
        spacing: Config.desktop.spacing

        Repeater {
            model: DesktopService.items

            delegate: DesktopIcon {
                required property string name
                required property string path
                required property string type
                required property string icon
                required property bool isDesktopFile
                required property int index

                itemName: name
                itemPath: path
                itemType: type
                itemIcon: icon

                onActivated: {
                    console.log("Activated:", itemName);
                }

                onContextMenuRequested: {
                    console.log("Context menu requested for:", itemName);
                }
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 200
        height: 60
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: Config.roundness
        visible: !DesktopService.initialLoadComplete

        Text {
            anchors.centerIn: parent
            text: "Loading desktop..."
            color: "white"
            font.family: Config.defaultFont
            font.pixelSize: Config.theme.fontSize
        }
    }
}
