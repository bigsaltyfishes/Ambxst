import QtQuick
import qs.modules.components
import qs.modules.services

ActionGrid {
    id: root
    
    signal itemSelected()
    
    layout: "row"
    buttonSize: 48
    spacing: 12
    
    actions: [
        {
            icon: "\uf023",
            tooltip: "Lock Session",
            command: "loginctl lock-session"
        },
        {
            icon: "\uf186", 
            tooltip: "Suspend",
            command: "systemctl suspend"
        },
        {
            icon: "\uf2f5",
            tooltip: "Exit Hyprland", 
            command: "hyprctl dispatch exit"
        },
        {
            icon: "\uf2f1",
            tooltip: "Reboot",
            command: "systemctl reboot"
        },
        {
            icon: "\uf011",
            tooltip: "Power Off",
            command: "systemctl poweroff"
        }
    ]
    
    onActionTriggered: (action) => {
        console.log("Executing power action:", action.command)
        root.itemSelected()
    }
}