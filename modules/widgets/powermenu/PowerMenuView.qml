import QtQuick
import qs.modules.components
import qs.modules.services

Item {
    implicitWidth: 300
    implicitHeight: 60

    PowerMenu {
        anchors.fill: parent
        
        onItemSelected: {
            Visibilities.setActiveModule("")
        }
    }
}