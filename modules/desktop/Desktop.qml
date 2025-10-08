import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.desktop
import qs.modules.services
import qs.config

PanelWindow {
    id: desktop

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

    GridView {
        id: gridView
        anchors.fill: parent
        anchors.margins: Config.desktop.spacing

        cellWidth: Config.desktop.iconSize + Config.desktop.spacing
        cellHeight: Config.desktop.iconSize + Config.desktop.spacing + 40

        model: DesktopService.items

        flow: GridView.FlowTopToBottom

        delegate: DesktopIcon {
            required property string name
            required property string path
            required property string type
            required property string icon
            required property bool isDesktopFile

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
