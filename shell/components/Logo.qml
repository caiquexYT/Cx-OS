import QtQuick
import qs.services

// Cx OS logo: rounded tile with the "Cx" monogram
Item {
    id: root

    readonly property real designWidth: 128
    readonly property real designHeight: 128

    property color topColour: Colours.palette.m3primary
    property color bottomColour: Colours.palette.m3onPrimary

    implicitWidth: designWidth
    implicitHeight: designHeight

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height)
        height: width
        radius: width * 0.28
        color: root.topColour

        Text {
            anchors.centerIn: parent
            text: "Cx"
            color: root.bottomColour
            font.family: "Rubik"
            font.weight: Font.Bold
            font.pixelSize: parent.height * 0.5
        }
    }
}
