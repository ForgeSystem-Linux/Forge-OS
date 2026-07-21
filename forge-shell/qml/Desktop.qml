import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: desktop
    width: parent.width
    height: parent.height
    color: "#1e1e2e"

    // Desktop icons grid
    GridView {
        id: iconGrid
        anchors.fill: parent
        anchors.margins: 20
        anchors.bottomMargin: 60
        cellWidth: 110
        cellHeight: 110

        model: ListModel {
            ListElement { name: "Home"; icon: "📁"; path: "/" }
            ListElement { name: "Terminal"; icon: "💻"; path: "terminal" }
            ListElement { name: "Settings"; icon: "⚙️"; path: "settings" }
            ListElement { name: "Files"; icon: "📂"; path: "files" }
            ListElement { name: "Browser"; icon: "🌐"; path: "browser" }
            ListElement { name: "Trash"; icon: "🗑️"; path: "trash" }
        }

        delegate: Item {
            width: 100
            height: 100

            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                color: iconMouse.containsMouse ? "#313244" : "transparent"
                radius: 8

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: model.icon
                        font.pixelSize: 32
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: model.name
                        color: "#cdd6f4"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onDoubleClicked: {
                        // TODO: Launch application
                    }
                }
            }
        }
    }

    // Right-click context menu
    Menu {
        id: contextMenu
        background: Rectangle {
            color: "#1e1e2e"
            border.color: "#313244"
            border.width: 1
            radius: 8
        }

        MenuItem {
            text: "Change Background"
            contentItem: Text {
                text: parent.text
                color: "#cdd6f4"
            }
            onTriggered: {
                // TODO: Open background settings
            }
        }
        MenuItem {
            text: "Display Settings"
            contentItem: Text {
                text: parent.text
                color: "#cdd6f4"
            }
            onTriggered: {
                // TODO: Open display settings
            }
        }
        MenuSeparator {
            contentItem: Rectangle {
                height: 1
                color: "#313244"
            }
        }
        MenuItem {
            text: "Open Terminal"
            contentItem: Text {
                text: parent.text
                color: "#cdd6f4"
            }
            onTriggered: {
                // TODO: Launch terminal
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup()
            }
        }
    }

    // Wallpaper pattern (subtle)
    Canvas {
        anchors.fill: parent
        opacity: 0.05
        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = "#89b4fa"
            for (var i = 0; i < width; i += 50) {
                for (var j = 0; j < height; j += 50) {
                    ctx.fillRect(i, j, 1, 1)
                }
            }
        }
    }
}
