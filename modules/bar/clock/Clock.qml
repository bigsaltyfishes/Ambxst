import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.theme
import qs.modules.components

BgRect {
    id: clockContainer

    // Time values
    property string currentTime: ""                  // raw time hh:mm:ss
    property string currentTimeVertical: ""          // time with colons -> newlines

    required property var bar
    property bool vertical: bar.orientation === "vertical"

    Layout.preferredWidth: vertical ? 36 : (timeDisplay.implicitWidth + 20)
    implicitHeight: vertical ? columnLayout.implicitHeight + 24 : 36
    Layout.preferredHeight: implicitHeight

    RowLayout { // horizontal layout
        id: rowLayout
        visible: !vertical
        anchors.centerIn: parent

        Text {
            id: timeDisplay
            text: clockContainer.currentTime
            color: Colors.overBackground
            font.pixelSize: Config.theme.fontSize
            font.family: Config.theme.font
            font.bold: true
        }
    }

    ColumnLayout { // vertical layout
        id: columnLayout
        visible: vertical
        anchors.centerIn: parent
        Layout.alignment: Qt.AlignHCenter

        Text {
            id: timeDisplayV
            text: clockContainer.currentTimeVertical
            color: Colors.overBackground
            font.pixelSize: Config.theme.fontSize
            font.family: Config.theme.font
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.NoWrap
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Timer {
        // update time every second
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date();
            var rawTime = Qt.formatDateTime(now, "hh:mm");
            clockContainer.currentTime = rawTime; // horizontal
            clockContainer.currentTimeVertical = rawTime.replace(/:/g, '\n'); // vertical variant
        }
    }

    Component.onCompleted: {
        var now = new Date();
        var rawTime = Qt.formatDateTime(now, "hh:mm");
        clockContainer.currentTime = rawTime;
        clockContainer.currentTimeVertical = rawTime.replace(/:/g, '\n');
    }
}
