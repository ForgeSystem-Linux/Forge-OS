import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: root
    visible: true
    width: 900
    height: 600
    title: "Forge Display Manager"
    color: "#0c0c14"

    property bool testMode: false
    property string selectedUser: ""
    property string password: ""
    property bool showPassword: false
    property bool authenticating: false
    property string errorMsg: ""
    property int currentIndex: 0
    property var users: []

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm:ss")
    }

    Component.onCompleted: {
        users = [
            { name: "admin", home: "/home/admin" },
            { name: "user", home: "/home/user" }
        ]
        if (users.length > 0) selectedUser = users[0].name
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0c0c14" }
            GradientStop { position: 0.5; color: "#111122" }
            GradientStop { position: 1.0; color: "#0c0c14" }
        }
    }

    Canvas {
        anchors.fill: parent; opacity: 0.008
        onPaint: {
            var ctx = getContext("2d"); ctx.strokeStyle = "#89b4fa"; ctx.lineWidth = 0.5
            for (var i = 0; i < width; i += 100) { ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, height); ctx.stroke() }
            for (var j = 0; j < height; j += 100) { ctx.beginPath(); ctx.moveTo(0, j); ctx.lineTo(width, j); ctx.stroke() }
        }
    }

    // Test mode banner
    Rectangle {
        visible: root.testMode
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 28
        color: "#f38ba8"
        z: 100

        Text {
            anchors.centerIn: parent
            text: "TEST MODE - Forge Display Manager"
            color: "#0c0c14"
            font.pixelSize: 12
            font.bold: true
        }
    }

    // Clock
    Column {
        anchors.top: parent.top
        anchors.topMargin: root.testMode ? 108 : 80
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Text {
            id: clockText
            color: "#cdd6f4"
            font.pixelSize: 72
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(new Date(), "hh:mm:ss")
        }

        Text {
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            color: "#6c7086"
            font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Login card
    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60
        width: 380
        height: 340
        radius: 20
        color: "#14141e"
        border.color: "#2a2a3c"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 20

            Rectangle {
                width: 72; height: 72; radius: 36
                color: "#1e1e2e"
                border.color: "#89b4fa"; border.width: 2
                Layout.alignment: Qt.AlignHCenter

                Text {
                    anchors.centerIn: parent
                    text: selectedUser ? selectedUser.charAt(0).toUpperCase() : "?"
                    color: "#89b4fa"
                    font.pixelSize: 28
                    font.bold: true
                }
            }

            Text {
                text: selectedUser
                color: "#cdd6f4"
                font.pixelSize: 20
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 10
                color: "#1e1e2e"
                border.color: passwordInput.activeFocus ? "#89b4fa" : (errorMsg ? "#f38ba8" : "#2a2a3c")
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Item { width: 12; height: 1
                        Text { text: "\u{1F511}"; color: "#6c7086"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter } }

                    TextInput {
                        id: passwordInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#cdd6f4"
                        font.pixelSize: 14
                        echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                        clip: true
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true

                        Keys.onReturnPressed: doLogin()
                        Keys.onEnterPressed: doLogin()

                        Text {
                            text: "Password"
                            color: "#45475a"
                            font.pixelSize: 14
                            visible: !passwordInput.text && !passwordInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: 6
                        color: eyeMA.containsMouse ? "#2a2a3c" : "transparent"
                        Layout.rightMargin: 8

                        Text {
                            anchors.centerIn: parent
                            text: root.showPassword ? "\u{1F441}" : "\u{1F441}\u{200D}\u{1F5E8}"
                            font.pixelSize: 14
                            opacity: 0.6
                        }

                        MouseArea {
                            id: eyeMA
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.showPassword = !root.showPassword
                        }
                    }
                }
            }

            Text {
                text: root.errorMsg
                color: "#f38ba8"
                font.pixelSize: 12
                visible: root.errorMsg !== ""
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 10
                color: loginMA.containsMouse ? Qt.lighter("#89b4fa", 0.85) : "#89b4fa"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: root.authenticating ? "Signing in..." : "Sign In"
                    color: "#0c0c14"
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: loginMA
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: doLogin()
                }
            }

            ComboBox {
                id: sessionCombo
                Layout.fillWidth: true
                model: ["Forge (Wayland)", "Forge (X11)", "Hyprland", "Alacritty"]
                currentIndex: 0
                background: Rectangle { radius: 8; color: "#1e1e2e"; border.color: "#2a2a3c"; border.width: 1 }
                contentItem: Text { text: sessionCombo.displayText; color: "#a1a1aa"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; leftPadding: 12 }
            }
        }
    }

    // User switcher
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: 24
        spacing: 8

        Repeater {
            model: users
            delegate: Rectangle {
                width: 36; height: 36; radius: 18
                color: index === root.currentIndex ? "#89b4fa" : "#1e1e2e"
                border.color: index === root.currentIndex ? "#89b4fa" : "#2a2a3c"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: modelData.name.charAt(0).toUpperCase()
                    color: index === root.currentIndex ? "#0c0c14" : "#a1a1aa"
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.currentIndex = index
                        root.selectedUser = modelData.name
                        passwordInput.text = ""
                        root.errorMsg = ""
                    }
                }
            }
        }
    }

    // Power buttons
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        spacing: 8

        Repeater {
            model: [
                { icon: "\u21BA", action: "reboot" },
                { icon: "\u23FB", action: "poweroff" }
            ]
            delegate: Rectangle {
                width: 36; height: 36; radius: 8
                color: pwrMA.containsMouse ? (modelData.action === "poweroff" ? "#f38ba8" : "#89b4fa") : "#1e1e2e"
                border.color: "#2a2a3c"; border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    color: pwrMA.containsMouse ? "#0c0c14" : "#a1a1aa"
                    font.pixelSize: 14
                }

                MouseArea {
                    id: pwrMA
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: console.log("Power:", modelData.action)
                }
            }
        }
    }

    function doLogin() {
        if (root.authenticating) return
        if (passwordInput.text === "") {
            root.errorMsg = "Please enter your password"
            return
        }

        root.authenticating = true
        root.errorMsg = ""

        loginTimer.start()
    }

    Timer {
        id: loginTimer
        interval: 500
        onTriggered: {
            root.authenticating = false
            console.log("Login:", root.selectedUser, "Session:", sessionCombo.currentText)
            root.errorMsg = "Login would launch: " + sessionCombo.currentText
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Up) {
                root.currentIndex = Math.max(0, root.currentIndex - 1)
                root.selectedUser = users[root.currentIndex].name
            } else if (event.key === Qt.Key_Down) {
                root.currentIndex = Math.min(users.length - 1, root.currentIndex + 1)
                root.selectedUser = users[root.currentIndex].name
            } else if (event.key === Qt.Key_Escape) {
                passwordInput.text = ""
                root.errorMsg = ""
            }
        }
    }
}
