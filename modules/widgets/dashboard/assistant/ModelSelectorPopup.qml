import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.theme
import qs.config
import qs.modules.services
import qs.modules.components

Popup {
    id: root
    
    width: 300
    height: Math.min(contentItem.implicitHeight + 20, 400)
    
    // Center in parent
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    background: StyledRect {
        variant: "popup"
        radius: Styling.radius(8)
        enableShadow: true
        border.width: 1
        border.color: Colors.outline
    }
    
    contentItem: ColumnLayout {
        spacing: 0
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.margins: 4
            spacing: 4
            
            Item { Layout.fillWidth: true } // Spacer
            
            Text {
                text: "Select Model"
                font.family: Config.theme.font
                font.weight: Font.Bold
                font.pixelSize: 14
                color: Colors.overSurface
            }
            
            Item { Layout.fillWidth: true } // Spacer
            
            // Refresh Button
            Button {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                flat: true
                padding: 0
                
                contentItem: Item {
                    anchors.fill: parent
                    
                    Text {
                        anchors.centerIn: parent
                        text: Icons.arrowCounterClockwise
                        font.family: Icons.font
                        font.pixelSize: 14
                        color: Colors.primary
                        visible: !Ai.fetchingModels
                    }
                    
                    // Spinner
                    Rectangle {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        radius: 7
                        color: "transparent"
                        border.width: 2
                        border.color: Colors.primary
                        visible: Ai.fetchingModels
                        
                        Rectangle {
                            width: 6; height: 6
                            radius: 3
                            color: Colors.surface
                            x: -1; y: -1
                        }
                        
                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 1000
                            running: Ai.fetchingModels
                        }
                    }
                }
                
                background: StyledRect {
                    variant: parent.hovered ? "focus" : "transparent"
                    radius: Styling.radius(4)
                }
                
                onClicked: Ai.fetchAvailableModels()
            }
        }
        
        Separator { Layout.fillWidth: true; vert: false }
        
        // Model List
        ListView {
            id: modelList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Math.min(contentHeight, 350)
            clip: true
            
            // Generate valid model data from Ai.models
            model: {
                let m = [];
                for(let i=0; i<Ai.models.length; i++) {
                    m.push(Ai.models[i]);
                }
                return m;
            }
            
            // Group by api_format (provider)
            section.property: "api_format"
            section.criteria: ViewSection.FullString
            section.delegate: Item {
                width: modelList.width
                height: 30
                
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    // Capitalize first letter
                    text: section.charAt(0).toUpperCase() + section.slice(1)
                    color: Colors.primary
                    font.family: Config.theme.font
                    font.weight: Font.Bold
                    font.pixelSize: 11
                }
            }
            
            delegate: Button {
                width: modelList.width
                height: 40
                flat: true
                leftPadding: 0
                rightPadding: 0
                
                contentItem: RowLayout {
                    anchors.fill: parent
                    spacing: 12
                    
                    // Selected Indicator
                    Item {
                        Layout.preferredWidth: 4
                        Layout.fillHeight: true
                        
                        Rectangle {
                            anchors.centerIn: parent
                            width: 4
                            height: 16
                            radius: 2
                            color: Colors.primary
                            visible: Ai.currentModel.name === modelData.name
                        }
                    }
                    
                    // Icon
                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        
                       Text {
                            anchors.centerIn: parent
                            text: {
                                switch(modelData.icon) {
                                    case "sparkles": return Icons.sparkle;
                                    case "openai": return Icons.lightning;
                                    case "wind": return Icons.sparkle; // Fallback
                                    default: return Icons.robot;
                                }
                            }
                            font.family: Icons.font
                            font.pixelSize: 16
                            color: Ai.currentModel.name === modelData.name ? Colors.primary : Colors.overSurface
                        }
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: Ai.currentModel.name === modelData.name ? Colors.primary : Colors.overSurface
                        font.family: Config.theme.font
                        font.pixelSize: 13
                    }
                }
                
                background: StyledRect {
                    variant: parent.hovered ? "focus" : "transparent"
                    radius: Styling.radius(4)
                }
                
                onClicked: {
                    Ai.setModel(modelData.name);
                    root.close();
                }
            }
        }
    }
}
