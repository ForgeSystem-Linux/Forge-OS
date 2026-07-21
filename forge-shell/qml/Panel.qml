import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.forge.shell

Rectangle {
    id: panel
    width: parent.width
    height: 48
    color: "#1e1e2e"
    border.color: "#313244"
    border.width: 1

    // Shell state
    ShellState {
        id: shellState
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Start menu button
        Rectangle {
            id: startButton
            width: 64
            height: parent.height
            color: startButtonMouse.containsMouse ? "#45475a" : "#1e1e2e"

            Text {
                anchors.centerIn: parent
                text: "Forge"
                color: "#cdd6f4"
                font.pixelSize: 14
                font.bold: true
            }

            MouseArea {
                id: startButtonMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: shellState.toggle_start_menu()
            }
        }

        // Separator
        Rectangle {
            width: 1
            height: parent.height - 16
            color: "#313244"
            anchors.verticalCenter: parent.verticalCenter
        }

        // Task list
        ListView {
            id: taskList
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            clip: true

            model: ListModel {
                // Window list will be populated from compositor
            }

            delegate: Rectangle {
                width: 160
                height: parent.height
                color: model.focused ? "#45475a" : (taskMouse.containsMouse ? "#313244" : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 8

                    // App icon placeholder
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 4
                        color: "#585b70"
                        Text {
                            anchors.centerIn: parent
                            text: "📦"
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: model.title || "Window"
                        color: "#cdd6f4"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: taskMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        // TODO: Focus window
                    }
                }
            }
        }

        // Separator
        Rectangle {
            width: 1
            height: parent.height - 16
            color: "#313244"
            anchors.verticalCenter: parent.verticalCenter
        }

        // System tray
        SystemTray {
            height: parent.height
        }

        // Separator
        Rectangle {
            width: 1
            height: parent.height - 16
            color: "#313244"
            anchors.verticalCenter: parent.verticalCenter
        }

        // Notification area
        Rectangle {
            width: notificationRow.width + 24
            height: parent.height

            Row {
                id: notificationRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "🔔"
                    font.pixelSize: 14
                    visible: shellState.notificationCount > 0
                }

                Text {
                    text: shellState.notificationCount.toString()
                    color: "#f38ba8"
                    font.pixelSize: 12
                    visible: shellState.notificationCount > 0
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: shellState.clearNotifications()
            }
        }

        // Separator
        Rectangle {
            width: 1
            height: parent.height - 16
            color: "#313244"
            anchors.verticalCenter: parent.verticalCenter
        }

        // Clock
        Rectangle {
            width: clockLabel.width + 24
            height: parent.height

            Label {
                id: clockLabel
                anchors.centerIn: parent
                color: "#cdd6f4"
                font.pixelSize: 13
                text: Qt.formatTime(new Date(), "hh:mm")
            }

            Timer {
                interval: 60000
                running: true
                repeat: true
                onTriggered: clockLabel.text = Qt.formatTime(new Date(), "hh:mm")
            }
        }
    }
}
