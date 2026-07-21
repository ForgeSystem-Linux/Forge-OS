import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    width: 800
    height: 600
    title: "Forge Settings"
    visible: true

    RowLayout {
        anchors.fill: parent

        // Sidebar
        ListView {
            id: sidebar
            width: 200
            Layout.fillHeight: true
            model: ListModel {
                ListElement { name: "General"; icon: "⚙️" }
                ListElement { name: "Appearance"; icon: "🎨" }
                ListElement { name: "Display"; icon: "🖥️" }
                ListElement { name: "Sound"; icon: "🔊" }
                ListElement { name: "Keyboard"; icon: "⌨️" }
                ListElement { name: "Mouse"; icon: "🖱️" }
            }

            delegate: ItemDelegate {
                width: parent.width
                height: 48
                background: Rectangle {
                    color: hovered ? "#3d3d3d" : "transparent"
                }
                contentItem: RowLayout {
                    spacing: 12
                    Text { text: icon; font.pixelSize: 16 }
                    Text { text: name; color: "white" }
                }
            }
        }

        // Content area
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // General settings
            ColumnLayout {
                spacing: 16

                Text {
                    text: "General Settings"
                    font.pixelSize: 24
                    font.bold: true
                }

                // Settings content will go here
            }
        }
    }
}
