import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout {
    id: systemTray
    spacing: 4

    // Tray icons will be populated dynamically
    Repeater {
        model: ListModel {
            // System tray icons will be added here
        }

        Rectangle {
            width: 28
            height: 28
            radius: 4
            color: trayMouse.containsMouse ? "#45475a" : "transparent"

            Text {
                anchors.centerIn: parent
                text: model.icon || "📎"
                font.pixelSize: 14
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        trayMenu.popup()
                    } else {
                        // Left click - show tray menu
                    }
                }
            }
        }
    }

    // Placeholder for when no tray icons
    Text {
        text: "📡"
        font.pixelSize: 14
        opacity: 0.5
    }

    // Context menu for tray
    Menu {
        id: trayMenu
        background: Rectangle {
            color: "#1e1e2e"
            border.color: "#313244"
            border.width: 1
            radius: 8
        }

        MenuItem {
            text: "Network"
            contentItem: Text { text: parent.text; color: "#cdd6f4" }
        }
        MenuItem {
            text: "Sound"
            contentItem: Text { text: parent.text; color: "#cdd6f4" }
        }
        MenuSeparator {
            contentItem: Rectangle { height: 1; color: "#313244" }
        }
        MenuItem {
            text: "Settings"
            contentItem: Text { text: parent.text; color: "#cdd6f4" }
        }
    }
}
