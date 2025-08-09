import QtQuick
import qs.modules.widgets.overview
import qs.modules.services

Item {
    property var currentScreen

    implicitWidth: overviewItem.implicitWidth
    implicitHeight: overviewItem.implicitHeight

    Overview {
        id: overviewItem
        anchors.centerIn: parent
        currentScreen: parent.currentScreen

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                Visibilities.setActiveModule("");
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            Qt.callLater(() => {
                forceActiveFocus();
            });
        }
    }
}