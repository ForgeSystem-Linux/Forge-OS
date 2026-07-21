import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.forge.shell

Rectangle {
    id: startMenu
    width: 360
    height: 500
    color: "#1e1e2e"
    border.color: "#313244"
    border.width: 1
    radius: 12
    visible: false

    // Shell state
    ShellState {
        id: shellState
    }

    // Connect to shell state changes
    Connections {
        target: shellState
        function onStartMenuVisibleChanged() {
            startMenu.visible = shellState.isStartMenuVisible()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Search bar
        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Search applications..."
            color: "#cdd6f4"
            placeholderTextColor: "#6c7086"
            background: Rectangle {
                color: "#313244"
                radius: 8
                border.color: searchField.activeFocus ? "#89b4fa" : "transparent"
                border.width: 1
            }
            leftPadding: 12
            font.pixelSize: 14
        }

        // Category tabs
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: ["All", "System", "Development", "Accessories"]

                Rectangle {
                    width: categoryText.width + 16
                    height: 28
                    radius: 14
                    color: index === 0 ? "#89b4fa" : "#313244"

                    Text {
                        id: categoryText
                        anchors.centerIn: parent
                        text: modelData
                        color: index === 0 ? "#1e1e2e" : "#cdd6f4"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // TODO: Filter apps by category
                        }
                    }
                }
            }
        }

        // Application list
        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4

            model: ListModel {
                ListElement { name: "Terminal"; icon: "💻"; category: "System" }
                ListElement { name: "Files"; icon: "📂"; category: "Accessories" }
                ListElement { name: "Settings"; icon: "⚙️"; category: "System" }
                ListElement { name: "Browser"; icon: "🌐"; category: "Accessories" }
                ListElement { name: "Text Editor"; icon: "📝"; category: "Development" }
                ListElement { name: "Calculator"; icon: "🔢"; category: "Accessories" }
                ListElement { name: "System Monitor"; icon: "📊"; category: "System" }
                ListElement { name: "Image Viewer"; icon: "🖼️"; category: "Accessories" }
            }

            delegate: Rectangle {
                width: parent.width
                height: 44
                color: appMouse.containsMouse ? "#313244" : "transparent"
                radius: 8

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12

                    // App icon
                    Rectangle {
                        width: 32
                        height: 32
                        color: "#45475a"
                        radius: 6

                        Text {
                            anchors.centerIn: parent
                            text: model.icon
                            font.pixelSize: 16
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: model.name
                        color: "#cdd6f4"
                        font.pixelSize: 14
                    }

                    Text {
                        text: model.category
                        color: "#6c7086"
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        // TODO: Launch application
                        shellState.toggle_start_menu()
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#313244"
        }

        // Power options
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // User info
            RowLayout {
                spacing: 8

                Rectangle {
                    width: 32
                    height: 32
                    color: "#45475a"
                    radius: 16

                    Text {
                        anchors.centerIn: parent
                        text: "👤"
                        font.pixelSize: 16
                    }
                }

                Text {
                    text: "User"
                    color: "#cdd6f4"
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            // Power buttons
            Repeater {
                model: [
                    { icon: "🔒", action: "lock" },
                    { icon: "⏻", action: "power" }
                ]

                Rectangle {
                    width: 40
                    height: 40
                    radius: 8
                    color: powerMouse.containsMouse ? "#45475a" : "#313244"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.pixelSize: 18
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (modelData.action === "power") {
                                // TODO: Show power off dialog
                            } else if (modelData.action === "lock") {
                                // TODO: Lock screen
                            }
                        }
                    }
                }
            }
        }
    }
}
