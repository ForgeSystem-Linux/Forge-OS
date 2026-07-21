import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: notificationPopup
    width: 360
    height: Math.min(notificationList.contentHeight + 32, 400)
    color: "#1e1e2e"
    border.color: "#313244"
    border.width: 1
    radius: 12
    visible: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Notifications"
                color: "#cdd6f4"
                font.pixelSize: 16
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Clear all button
            Rectangle {
                width: clearText.width + 16
                height: 24
                radius: 12
                color: clearMouse.containsMouse ? "#45475a" : "#313244"

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear All"
                    color: "#89b4fa"
                    font.pixelSize: 11
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        // TODO: Clear all notifications
                    }
                }
            }
        }

        // Notification list
        ListView {
            id: notificationList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8

            model: ListModel {
                // Notifications will be added here
            }

            delegate: Rectangle {
                width: parent.width
                height: 72
                color: notifMouse.containsMouse ? "#313244" : "transparent"
                radius: 8

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // App icon
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#45475a"
                        radius: 8

                        Text {
                            anchors.centerIn: parent
                            text: model.appIcon || "🔔"
                            font.pixelSize: 20
                        }
                    }

                    // Notification content
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Text {
                                Layout.fillWidth: true
                                text: model.appName || "Unknown"
                                color: "#6c7086"
                                font.pixelSize: 11
                            }
                            Text {
                                text: model.time || "now"
                                color: "#6c7086"
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.summary || ""
                            color: "#cdd6f4"
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.body || ""
                            color: "#a6adc8"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                        }
                    }

                    // Close button
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: closeMouse.containsMouse ? "#f38ba8" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: "#f38ba8"
                            font.pixelSize: 12
                            visible: closeMouse.containsMouse
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                // TODO: Close notification
                            }
                        }
                    }
                }

                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            // TODO: Show notification actions
                        }
                    }
                }
            }
        }

        // Empty state
        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "No notifications"
            color: "#6c7086"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: notificationList.count === 0
        }
    }
}
