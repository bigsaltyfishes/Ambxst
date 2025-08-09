import QtQuick
import qs.modules.widgets.launcher
import qs.modules.globals
import qs.modules.services

Item {
    implicitWidth: 480
    implicitHeight: Math.min(launcherSearch.implicitHeight, 368)

    LauncherSearch {
        id: launcherSearch
        anchors.fill: parent

        onItemSelected: {
            GlobalStates.clearLauncherState();
            Visibilities.setActiveModule("");
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                GlobalStates.clearLauncherState();
                Visibilities.setActiveModule("");
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            Qt.callLater(() => {
                focusSearchInput();
            });
        }
    }
}