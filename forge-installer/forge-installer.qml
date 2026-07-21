import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: root
    visible: true
    width: 900
    height: 650
    title: "Forge System Installer"
    color: "#0c0c14"

    property bool testMode: false
    property int currentStep: 0
    property string installTarget: "/usr"
    property bool installSystem: true
    property bool enableDM: true
    property string hostname: "forge-pc"
    property var installLog: []
    property bool installing: false
    property int progress: 0
    property var installSteps: []

    function log(msg) {
        installLog.push(msg)
        installLogChanged()
    }

    function runInstall() {
        installing = true
        progress = 0

        var steps = [
            "install-base", "install-compositor", "install-shell",
            "install-services", "install-dbus", "install-polkit",
            "install-pam", "install-session", "install-icons",
            "enable-services", "set-permissions", "set-hostname " + hostname,
            "finish"
        ]

        installSteps = steps
        executeStep(0)
    }

    function executeStep(idx) {
        if (idx >= installSteps.length) {
            installing = false
            progress = 100
            currentStep = 4
            return
        }

        progress = Math.round((idx / installSteps.length) * 100)

        var step = installSteps[idx]
        var xhr = new XMLHttpRequest()

        if (root.testMode) {
            // Test mode - simulate install
            log("[" + (idx+1) + "/" + installSteps.length + "] " + step.replace("install-", "Installing ").replace("set-", "Setting ").replace("enable-", "Enabling "))
            stepTimer.idx = idx + 1
            stepTimer.start()
        } else {
            // Real install - call helper
            xhr.open("GET", "file:///usr/bin/forge-install-helper")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    log(xhr.responseText)
                    executeStep(idx + 1)
                }
            }
            xhr.send()
        }
    }

    Timer {
        id: stepTimer
        property int idx: 0
        interval: 200
        onTriggered: executeStep(idx)
    }

    Rectangle { anchors.fill: parent; color: "#0c0c14" }

    // Test mode banner
    Rectangle {
        visible: root.testMode
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 28; color: "#f38ba8"; z: 100
        Text { anchors.centerIn: parent; text: "TEST MODE - No changes will be made"; color: "#0c0c14"; font.pixelSize: 12; font.bold: true }
    }

    component InstallerButton: Button {
        property string label: text
        background: Rectangle { radius: 8; color: parent.hovered ? Qt.lighter("#89b4fa", 0.85) : "#89b4fa"; Behavior on color { ColorAnimation { duration: 150 } } }
        contentItem: Text { text: parent.label; color: "#0c0c14"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignHCenter }
    }

    // ===== WELCOME =====
    ColumnLayout {
        anchors.centerIn: parent; spacing: 32; visible: currentStep === 0
        Text { text: "F"; color: "#89b4fa"; font.pixelSize: 72; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        ColumnLayout { spacing: 8; Layout.alignment: Qt.AlignHCenter
            Text { text: "Install Forge DE"; color: "#cdd6f4"; font.pixelSize: 28; font.bold: true; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Forge Desktop Environment Installer v0.1.0"; color: "#6c7086"; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter } }
        Rectangle { Layout.preferredWidth: 500; Layout.preferredHeight: 120; radius: 10; color: "#14141e"; border.color: "#2a2a3c"; border.width: 1
            Column { anchors.centerIn: parent; spacing: 8
                Text { text: "This installer will:"; color: "#a1a1aa"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "\u2022 Install Forge compositor and shell\n\u2022 Set up systemd services\n\u2022 Configure display manager\n\u2022 Create user session"; color: "#6c7086"; font.pixelSize: 12; lineHeight: 1.5; anchors.horizontalCenter: parent.horizontalCenter } } }
        InstallerButton { text: "Start Installation"; Layout.preferredWidth: 200; Layout.preferredHeight: 44; Layout.alignment: Qt.AlignHCenter; onClicked: currentStep++ }
    }

    // ===== OPTIONS =====
    ColumnLayout {
        anchors.centerIn: parent; spacing: 24; visible: currentStep === 1; width: 600
        Text { text: "Installation Options"; color: "#cdd6f4"; font.pixelSize: 22; font.bold: true; Layout.alignment: Qt.AlignHCenter }

        ColumnLayout { spacing: 6; Layout.fillWidth: true
            Text { text: "Hostname"; color: "#a1a1aa"; font.pixelSize: 12 }
            Rectangle { Layout.fillWidth: true; height: 40; radius: 8; color: "#1e1e2e"; border.color: hostInput.activeFocus ? "#89b4fa" : "#2a2a3c"; border.width: 1
                TextInput { id: hostInput; anchors.verticalCenter: parent.verticalCenter; x: 12; width: parent.width - 24; color: "#cdd6f4"; font.pixelSize: 13; text: root.hostname; onTextChanged: root.hostname = text } } }

        RowLayout { spacing: 12; Layout.fillWidth: true
            Rectangle { width: 44; height: 24; radius: 12; color: enableDM ? "#89b4fa" : "#2a2a3c"
                Rectangle { x: enableDM ? 22 : 2; width: 20; height: 20; radius: 10; color: "white"; Behavior on x { NumberAnimation { duration: 150 } } }
                MouseArea { anchors.fill: parent; onClicked: enableDM = !enableDM } }
            Text { text: "Enable Forge Display Manager"; color: "#cdd6f4"; font.pixelSize: 13 } }

        // Dependencies check
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 10; color: "#14141e"; border.color: "#2a2a3c"; border.width: 1
            Column { anchors.centerIn: parent; spacing: 4
                Text { text: "Dependencies: Qt6, Wayland, libinput, libseat, Polkit, PAM"; color: "#a1a1aa"; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "All required packages are installed on this system"; color: "#a6e3a1"; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter } } }

        InstallerButton { text: "Next"; Layout.alignment: Qt.AlignHCenter; onClicked: currentStep++ }
    }

    // ===== CONFIRM =====
    ColumnLayout {
        anchors.centerIn: parent; spacing: 24; visible: currentStep === 2; width: 600
        Text { text: "Ready to Install"; color: "#cdd6f4"; font.pixelSize: 22; font.bold: true; Layout.alignment: Qt.AlignHCenter }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 180; radius: 10; color: "#14141e"; border.color: "#2a2a3c"; border.width: 1
            Column { anchors.fill: parent; anchors.margins: 16; spacing: 8
                Text { text: "Installation Summary"; color: "#89b4fa"; font.pixelSize: 14; font.bold: true }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2a3c" }
                Text { text: "Hostname: " + hostname; color: "#a1a1aa"; font.pixelSize: 12 }
                Text { text: "Display Manager: " + (enableDM ? "Enabled" : "Disabled"); color: "#a1a1aa"; font.pixelSize: 12 }
                Text { text: "Components: Compositor, Shell, Greeter, Services"; color: "#a1a1aa"; font.pixelSize: 12 } } }

        RowLayout { spacing: 12; Layout.alignment: Qt.AlignHCenter
            InstallerButton { text: "Back"; onClicked: currentStep--; background: Rectangle { radius: 8; color: parent.hovered ? "#2a2a3c" : "#1e1e2e"; border.color: "#2a2a3c"; border.width: 1 }
                contentItem: Text { text: parent.label; color: "#cdd6f4"; font.pixelSize: 14 } }
            InstallerButton { text: "Install"; Layout.preferredWidth: 200; Layout.preferredHeight: 44; onClicked: { currentStep = 3; runInstall() } } }
    }

    // ===== PROGRESS =====
    ColumnLayout {
        anchors.centerIn: parent; spacing: 24; visible: currentStep === 3; width: 600
        Text { text: root.testMode ? "Simulating Install..." : "Installing..."; color: "#cdd6f4"; font.pixelSize: 22; font.bold: true; Layout.alignment: Qt.AlignHCenter }

        Rectangle { Layout.fillWidth: true; height: 8; radius: 4; color: "#1e1e2e"
            Rectangle { width: root.progress * parent.width / 100; height: parent.height; radius: 4; color: "#89b4fa"; Behavior on width { NumberAnimation { duration: 300 } } } }

        Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; radius: 10; color: "#14141e"; border.color: "#2a2a3c"; border.width: 1
            ScrollView { anchors.fill: parent; anchors.margins: 8
                ListView { model: root.installLog.length
                    delegate: Text { width: parent ? parent.width : 0; text: root.installLog[index] || ""; color: "#a1a1aa"; font.pixelSize: 11; font.family: "monospace" } } } }
    }

    // ===== DONE =====
    ColumnLayout {
        anchors.centerIn: parent; spacing: 24; visible: currentStep === 4
        Text { text: "\u{2705}"; font.pixelSize: 64; Layout.alignment: Qt.AlignHCenter }
        Text { text: "Installation Complete!"; color: "#cdd6f4"; font.pixelSize: 24; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        Text { text: root.testMode ? "Test run finished. No changes were made." : "Forge has been installed successfully."; color: "#6c7086"; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }

        Rectangle { Layout.preferredWidth: 400; Layout.preferredHeight: 80; radius: 10; color: "#14141e"; border.color: "#2a2a3c"; border.width: 1
            Column { anchors.centerIn: parent; spacing: 4
                Text { text: "To start using Forge:"; color: "#89b4fa"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: enableDM ? "Reboot and select Forge from your display manager" : "Run: forge-compositor --backend winit"; color: "#a1a1aa"; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter } } }

        InstallerButton { text: "Done"; Layout.preferredWidth: 200; Layout.preferredHeight: 44; Layout.alignment: Qt.AlignHCenter; onClicked: Qt.quit() }
    }

    // Progress dots
    Row {
        anchors.bottom: parent.bottom; anchors.bottomMargin: root.testMode ? 36 : 20; anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
        Repeater { model: 5
            Rectangle { width: index === root.currentStep ? 20 : 8; height: 8; radius: 4; color: index === root.currentStep ? "#89b4fa" : "#2a2a3c"; Behavior on width { NumberAnimation { duration: 200 } } } }
    }
}
