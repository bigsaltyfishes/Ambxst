pragma Singleton
import QtQuick

Loader {
    id: root
    
    source: {
        var colorsPath = Qt.resolvedUrl("Colors.qml")
        var fallbackPath = Qt.resolvedUrl("fallbackColors.qml")
        
        // Try to load Colors.qml first
        var testComponent = Qt.createComponent(colorsPath, Component.PreferSynchronous)
        if (testComponent.status === Component.Ready) {
            testComponent.destroy()
            return colorsPath
        } else {
            testComponent.destroy()
            return fallbackPath
        }
    }
    
    // Proxy all properties from the loaded item
    property color foreground: item ? item.foreground : "#f0dede"
    property color background: item ? item.background : "#1a1111"
    property color cursor: item ? item.cursor : "#f0dede"
    property color primary: item ? item.primary : "#ffb3b5"
    property color primaryForeground: item ? item.primaryForeground : "#561d22"
    property color secondary: item ? item.secondary : "#e6bdbd"
    property color secondaryForeground: item ? item.secondaryForeground : "#44292a"
    property color tertiary: item ? item.tertiary : "#e6c08d"
    property color tertiaryForeground: item ? item.tertiaryForeground : "#432c05"
    property color surface: item ? item.surface : "#1a1111"
    property color surfaceBright: item ? item.surfaceBright : "#413737"
    property color error: item ? item.error : "#ffb4ab"
    property color errorDim: item ? item.errorDim : "#ff8678"
    property color errorForeground: item ? item.errorForeground : "#690005"
    property color errorContainer: item ? item.errorContainer : "#93000a"
    property color outline: item ? item.outline : "#9f8c8c"
    property color shadow: item ? item.shadow : "#000000"
    property color red: item ? item.red : "#ffb3af"
    property color redDim: item ? item.redDim : "#ff837c"
    property color green: item ? item.green : "#b7d085"
    property color greenDim: item ? item.greenDim : "#a1c260"
    property color yellow: item ? item.yellow : "#dec56e"
    property color yellowDim: item ? item.yellowDim : "#d5b444"
    property color blue: item ? item.blue : "#cebdfe"
    property color blueDim: item ? item.blueDim : "#a98bfd"
    property color magenta: item ? item.magenta : "#fcb0d5"
    property color magentaDim: item ? item.magentaDim : "#fa7fbb"
    property color cyan: item ? item.cyan : "#82d3e2"
    property color cyanDim: item ? item.cyanDim : "#59c4d8"
    property color white: item ? item.white : "#82d3e0"
}