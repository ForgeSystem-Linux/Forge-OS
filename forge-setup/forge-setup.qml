import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: root
    visible: true
    width: 800
    height: 600
    title: "Forge - Initial Setup"
    color: "#0c0c14"
    flags: Qt.Dialog

    property int currentStep: 0
    property bool includeAccountSetup: false
    property int totalSteps: includeAccountSetup ? 6 : 5
    property int selectedLang: 0
    property int selectedTheme: 0
    property int selectedWp: 0
    property string configDir: "/home/" + Qt.platform.userName + "/.config/forge"
    property string applyScript: "/usr/local/bin/forge-apply"

    property var accentColors: ["#89b4fa", "#cba6f7", "#a6e3a1", "#f9e2af", "#f38ba8", "#89dceb", "#94e2d5", "#f5c2e7"]
    property string accent: accentColors[selectedTheme]

    property var bgPresets: [
        { c1: "#0c0c14", c2: "#111122", c3: "#0c0c14" },
        { c1: "#1e1e2e", c2: "#313244", c3: "#1e1e2e" },
        { c1: "#181825", c2: "#1e1e2e", c3: "#11111b" },
        { c1: "#0c0c14", c2: "#0c0c14", c3: "#0c0c14" }
    ]

    property var langCodes: ["en", "es", "de", "fr", "ja", "ko", "zh", "pt", "ru", "it"]

    function applySetting(action, value) {
        var xhr = new XMLHttpRequest()
        xhr.open("POST", "file:///dev/null")
        // Use Qt.labs.folderlistmodel or just log for now
        console.log("Setting:", action, "=", value)
    }

    function stepVisible(step) {
        if (step === 0) return currentStep === 0
        if (step === 1) return currentStep === 1
        if (step === 2 && includeAccountSetup) return currentStep === 2
        if (step === 3) return currentStep === (includeAccountSetup ? 3 : 2)
        if (step === 4) return currentStep === (includeAccountSetup ? 4 : 3)
        if (step === 5) return currentStep === (includeAccountSetup ? 5 : 4)
        return false
    }

    Component.onCompleted: {
        // Check first run
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + configDir + "/config.toml")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                if (xhr.responseText.indexOf("first_run = false") >= 0) {
                    // Not first run, skip setup
                    console.log("Not first run, skipping setup")
                }
            }
        }
        xhr.send()
    }

    Rectangle { anchors.fill: parent; color: "#0c0c14" }

    component AccentButton: Button {
        property string label: text
        background: Rectangle {
            radius: 8
            color: parent.hovered ? Qt.lighter(root.accent, 0.85) : root.accent
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        contentItem: Text {
            text: parent.label; color: "#0c0c14"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignHCenter
        }
    }

    component AccentDot: Rectangle {
        property bool selected: false
        width: 20; height: 20; radius: 10
        border.color: selected ? root.accent : "#45475a"; border.width: 2
        Behavior on border.color { ColorAnimation { duration: 200 } }
        Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: parent.selected ? root.accent : "transparent" }
    }

    // ===== LANGUAGE =====
    ColumnLayout {
        anchors.centerIn: parent; spacing: 24; visible: stepVisible(0)

        Text { text: "F"; color: root.accent; font.pixelSize: 48; font.bold: true; Layout.alignment: Qt.AlignHCenter; Behavior on color { ColorAnimation { duration: 200 } } }
        Text { text: "Select your language"; color: "#cdd6f4"; font.pixelSize: 20; font.bold: true; Layout.alignment: Qt.AlignHCenter }

        Rectangle {
            Layout.preferredWidth: 400; Layout.preferredHeight: 300; radius: 12
            color: "#14141e"; border.color: "#2a2a3c"; border.width: 1
            ListView {
                anchors.fill: parent; anchors.margins: 12; clip: true
                model: ListModel {
                    ListElement { name: "English" }
                    ListElement { name: "Espa\u00f1ol" }
                    ListElement { name: "Deutsch" }
                    ListElement { name: "Fran\u00e7ais" }
                    ListElement { name: "\u65e5\u672c\u8a9e" }
                    ListElement { name: "\ud55c\uad6d\uc5b4" }
                    ListElement { name: "\u4e2d\u6587" }
                    ListElement { name: "Portugu\u00eas" }
                    ListElement { name: "\u0420\u0443\u0441\u0441\u043a\u0438\u0439" }
                    ListElement { name: "Italiano" }
                }
                delegate: Rectangle {
                    width: parent.width; height: 36; radius: 6
                    color: langMA.containsMouse ? "#2a2a3c" : (index === root.selectedLang ? "#1e1e2e" : "transparent")
                    border.color: index === root.selectedLang ? root.accent : "transparent"; border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Row { anchors.fill: parent; anchors.margins: 8; spacing: 12
                        AccentDot { selected: index === root.selectedLang; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: name; color: "#cdd6f4"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter } }
                    MouseArea { id: langMA; anchors.fill: parent; hoverEnabled: true; onClicked: root.selectedLang = index }
                }
            }
        }

        AccentButton { text: "Next"; Layout.alignment: Qt.AlignHCenter; onClicked: {
            applySetting("save-language", langCodes[root.selectedLang])
            currentStep++
        }}
    }

    // ===== WELCOME =====
    ColumnLayout {
        anchors.centerIn: parent; spacing: 32; visible: stepVisible(1)
        Text { text: "F"; color: root.accent; font.pixelSize: 72; font.bold: true; Layout.alignment: Qt.AlignHCenter; Behavior on color { ColorAnimation { duration: 200 } } }
        ColumnLayout { spacing: 8; Layout.alignment: Qt.AlignHCenter
            Text { text: "Welcome to Forge"; color: "#cdd6f4"; font.pixelSize: 32; font.bold: true; Layout.alignment: Qt.AlignHCenter }
            Text { text: "A modern Wayland desktop environment\nbuilt with Rust and Qt 6"; color: "#6c7086"; font.pixelSize: 15; lineHeight: 1.5; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter } }
        Button {
            text: "Begin Setup"; Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 200; Layout.preferredHeight: 44; onClicked: currentStep++
            background: Rectangle { radius: 10; color: parent.hovered ? Qt.lighter(root.accent, 0.85) : root.accent; Behavior on color { ColorAnimation { duration: 150 } } }
            contentItem: Text { text: parent.text; color: "#0c0c14"; font.pixelSize: 15; font.bold: true; horizontalAlignment: Text.AlignHCenter } }
    }

    // ===== APPEARANCE =====
    ColumnLayout {
        anchors.centerIn: parent; spacing: 24; visible: stepVisible(3); width: 500
        Text { text: "Appearance"; color: "#cdd6f4"; font.pixelSize: 22; font.bold: true; Layout.alignment: Qt.AlignHCenter }

        ColumnLayout { spacing: 8; Layout.alignment: Qt.AlignHCenter
            Text { text: "Accent Color"; color: "#a1a1aa"; font.pixelSize: 12 }
            Row { spacing: 8; Layout.alignment: Qt.AlignHCenter
                Repeater {
                    model: root.accentColors
                    delegate: Rectangle {
                        width: 32; height: 32; radius: 16; color: modelData
                        border.color: index === root.selectedTheme ? "white" : "transparent"; border.width: 2
                        scale: accMA.containsMouse ? 1.15 : 1.0; Behavior on scale { NumberAnimation { duration: 100 } }
                        MouseArea { id: accMA; anchors.fill: parent; hoverEnabled: true; onClicked: root.selectedTheme = index } } } }
        }

        ColumnLayout { spacing: 8; Layout.alignment: Qt.AlignHCenter
            Text { text: "Background"; color: "#a1a1aa"; font.pixelSize: 12 }
            Row { spacing: 8; Layout.alignment: Qt.AlignHCenter
                Repeater {
                    model: root.bgPresets
                    delegate: Rectangle {
                        width: 80; height: 50; radius: 8; color: modelData.c1
                        border.color: index === root.selectedWp ? "white" : "#2a2a3c"; border.width: index === root.selectedWp ? 2 : 1
                        gradient: Gradient { GradientStop { position: 0.0; color: modelData.c1 } GradientStop { position: 0.5; color: modelData.c2 } GradientStop { position: 1.0; color: modelData.c3 } }
                        scale: wpMA.containsMouse ? 1.05 : 1.0; Behavior on scale { NumberAnimation { duration: 100 } }
                        MouseArea { id: wpMA; anchors.fill: parent; hoverEnabled: true; onClicked: root.selectedWp = index } } } }
        }

        AccentButton { text: "Next"; Layout.alignment: Qt.AlignHCenter; onClicked: {
            applySetting("save-accent", accentColors[root.selectedTheme])
            currentStep++
        }}
    }

    // ===== KEYBOARD =====
    ColumnLayout {
        anchors.centerIn: parent; spacing: 16; visible: stepVisible(4); width: 400
        Text { text: "Keyboard"; color: "#cdd6f4"; font.pixelSize: 22; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        Repeater {
            model: ["us", "uk", "de", "fr", "es"]
            delegate: Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 40; radius: 8
                color: kbMA.containsMouse ? "#2a2a3c" : "transparent"
                border.color: kbMA.containsMouse ? root.accent : "#2a2a3c"; border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter
                    text: ["English (US)", "English (UK)", "Deutsch", "Fran\u00e7ais", "Espa\u00f1ol"][index]; color: "#cdd6f4"; font.pixelSize: 13 }
                MouseArea { id: kbMA; anchors.fill: parent; hoverEnabled: true; onClicked: {
                    applySetting("save-keyboard", modelData)
                    console.log("Keyboard:", modelData)
                }} } }
        AccentButton { text: "Next"; Layout.alignment: Qt.AlignHCenter; onClicked: currentStep++ }
    }

    // ===== COMPLETE =====
    ColumnLayout {
        anchors.centerIn: parent; spacing: 24; visible: stepVisible(5)
        Text { text: "\u{1F389}"; font.pixelSize: 64; Layout.alignment: Qt.AlignHCenter }
        Text { text: "You're all set!"; color: "#cdd6f4"; font.pixelSize: 24; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        Text { text: "Forge is ready. Enjoy your desktop!"; color: "#6c7086"; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }

        Button {
            text: "Start Using Forge"; Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 200; Layout.preferredHeight: 44
            onClicked: {
                // Save all settings
                applySetting("save-accent", accentColors[root.selectedTheme])
                applySetting("finish", "")
                Qt.quit()
            }
            background: Rectangle { radius: 10; color: parent.hovered ? Qt.lighter(root.accent, 0.85) : root.accent; Behavior on color { ColorAnimation { duration: 150 } } }
            contentItem: Text { text: parent.text; color: "#0c0c14"; font.pixelSize: 15; font.bold: true; horizontalAlignment: Text.AlignHCenter }
        }
    }

    // Progress dots
    Row {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 20; anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
        Repeater {
            model: totalSteps
            Rectangle {
                width: index === root.currentStep ? 20 : 8; height: 8; radius: 4
                color: index === root.currentStep ? root.accent : "#2a2a3c"
                Behavior on width { NumberAnimation { duration: 200 } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
