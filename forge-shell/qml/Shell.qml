import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: root
    visible: true
    width: 1920
    height: 1080
    title: "Forge"
    color: "#0c0c14"

    property bool showStartMenu: false
    property bool showPowerMenu: false
    property int activeWorkspace: 0
    property string clockTime: Qt.formatTime(new Date(), "hh:mm")
    property string dateStr: Qt.formatDate(new Date(), "ddd MMM d")
    property var apps: []
    property var desktopFiles: []

    Timer { interval: 1000; running: true; repeat: true; onTriggered: { clockTime = Qt.formatTime(new Date(), "hh:mm"); dateStr = Qt.formatDate(new Date(), "ddd MMM d") } }

    function loadApps() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + Qt.resolvedUrl("."))
        // We need to load from absolute path
        var path = "/home/" + Qt.platform.userName + "/.local/share/forge/apps.json"
        xhr.open("GET", "file://" + path)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                root.apps = JSON.parse(xhr.responseText)
            }
        }
        xhr.send()
    }

    function loadDesktop() {
        var xhr = new XMLHttpRequest()
        var path = "/home/" + Qt.platform.userName + "/.local/share/forge/desktop.json"
        xhr.open("GET", "file://" + path)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                root.desktopFiles = JSON.parse(xhr.responseText)
            }
        }
        xhr.send()
    }

    Component.onCompleted: { loadApps(); loadDesktop() }

    function parseColor(hex) {
        if (!hex || hex.length < 7) return Qt.rgba(0.5, 0.5, 0.5, 1)
        var r = parseInt(hex.substring(1,3), 16) / 255
        var g = parseInt(hex.substring(3,5), 16) / 255
        var b = parseInt(hex.substring(5,7), 16) / 255
        return Qt.rgba(r, g, b, 1.0)
    }

    function extIcon(name, isDir) {
        if (isDir) return "\u{1F4C1}"
        var n = name.toLowerCase()
        if (n.endsWith(".desktop")) return "\u{1F4E6}"
        if (n.endsWith(".sh")) return "\u{25B6}"
        if (n.endsWith(".py")) return "\u{1F40D}"
        if (n.endsWith(".rs")) return "\u{1F980}"
        if (n.endsWith(".js") || n.endsWith(".ts")) return "\u{26A1}"
        if (n.endsWith(".png") || n.endsWith(".jpg") || n.endsWith(".gif") || n.endsWith(".svg")) return "\u{1F5BC}"
        if (n.endsWith(".mp3") || n.endsWith(".flac")) return "\u{266B}"
        if (n.endsWith(".mp4") || n.endsWith(".mkv")) return "\u{25B6}"
        if (n.endsWith(".pdf")) return "\u{1F4D6}"
        if (n.endsWith(".zip") || n.endsWith(".tar") || n.endsWith(".gz")) return "\u{1F4E6}"
        return "\u{1F4C4}"
    }

    function extColor(name, isDir) {
        if (isDir) return "#89b4fa"
        var n = name.toLowerCase()
        if (n.endsWith(".sh")) return "#a6e3a1"
        if (n.endsWith(".py")) return "#f9e2af"
        if (n.endsWith(".rs")) return "#f38ba8"
        if (n.endsWith(".desktop")) return "#89b4fa"
        if (n.endsWith(".md") || n.endsWith(".txt")) return "#cdd6f4"
        if (n.endsWith(".png") || n.endsWith(".jpg")) return "#cba6f7"
        return "#a1a1aa"
    }

    function appIcon(name) {
        var n = name.toLowerCase()
        if (n.includes("terminal") || n.includes("konsole") || n.includes("alacritty") || n.includes("kitty")) return "\u{1F4BB}"
        if (n.includes("file") || n.includes("nautilus") || n.includes("dolphin") || n.includes("thunar")) return "\u{1F4C2}"
        if (n.includes("browser") || n.includes("firefox") || n.includes("chrome") || n.includes("chromium")) return "\u{1F310}"
        if (n.includes("editor") || n.includes("code") || n.includes("kate") || n.includes("vim")) return "\u{270E}"
        if (n.includes("setting") || n.includes("config")) return "\u2699"
        if (n.includes("calc")) return "\u{1F5A2}"
        if (n.includes("image") || n.includes("gwenview")) return "\u{1F5BC}"
        if (n.includes("music") || n.includes("spotify") || n.includes("audio")) return "\u{266B}"
        if (n.includes("video") || n.includes("vlc") || n.includes("player")) return "\u{25B6}"
        if (n.includes("steam") || n.includes("game")) return "\u{1F3AE}"
        if (n.includes("disc") || n.includes("chat") || n.includes("slack")) return "\u{1F4AC}"
        if (n.includes("doc") || n.includes("pdf") || n.includes("viewer")) return "\u{1F4D6}"
        if (n.includes("monitor") || n.includes("system")) return "\u{1F4CA}"
        if (n.includes("network") || n.includes("wifi") || n.includes("bluetooth")) return "\u{1F4E1}"
        return "\u{1F4E6}"
    }

    // Wallpaper
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0c0c14" }
            GradientStop { position: 0.5; color: "#111122" }
            GradientStop { position: 1.0; color: "#0c0c14" }
        }
    }

    Canvas {
        anchors.fill: parent; opacity: 0.012
        onPaint: {
            var ctx = getContext("2d"); ctx.strokeStyle = "#89b4fa"; ctx.lineWidth = 0.5
            for (var i = 0; i < width; i += 80) { ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, height); ctx.stroke() }
            for (var j = 0; j < height; j += 80) { ctx.beginPath(); ctx.moveTo(0, j); ctx.lineTo(width, j); ctx.stroke() }
        }
    }

    // ===== PANEL =====
    Rectangle {
        id: panel; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 40; color: "#14141e"; border.color: "#1e1e2e"; border.width: 1; z: 100
        RowLayout { anchors.fill: parent; spacing: 0
            Rectangle {
                Layout.preferredWidth: 52; Layout.fillHeight: true
                color: logoMA.containsMouse ? "#1e1e2e" : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { anchors.centerIn: parent; text: "F"; color: "#89b4fa"; font.pixelSize: 18; font.bold: true }
                MouseArea { id: logoMA; anchors.fill: parent; hoverEnabled: true; onClicked: { root.showStartMenu = !root.showStartMenu; root.showPowerMenu = false } }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#1e1e2e"; Layout.topMargin: 8; Layout.bottomMargin: 8 }
            Repeater {
                model: 4
                delegate: Rectangle {
                    Layout.preferredWidth: 32; Layout.preferredHeight: 24; Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 2; Layout.rightMargin: 2; radius: 6
                    color: index === root.activeWorkspace ? "#89b4fa" : (wsMA.containsMouse ? "#1e1e2e" : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: (index + 1).toString(); color: index === root.activeWorkspace ? "#0c0c14" : "#6c7086"; font.pixelSize: 11; font.bold: index === root.activeWorkspace }
                    MouseArea { id: wsMA; anchors.fill: parent; hoverEnabled: true; onClicked: root.activeWorkspace = index }
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#1e1e2e"; Layout.topMargin: 8; Layout.bottomMargin: 8 }
            Item { Layout.fillWidth: true; Layout.fillHeight: true }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#1e1e2e"; Layout.topMargin: 8; Layout.bottomMargin: 8 }
            Row { spacing: 10; Layout.fillHeight: true; Layout.rightMargin: 12; Layout.leftMargin: 12
                Repeater { model: ["\u{1F50A}", "\u{1F4BB}", "\u{1F310}"]
                    delegate: Text { text: modelData; font.pixelSize: 12; opacity: tMA.containsMouse ? 1.0 : 0.5; anchors.verticalCenter: parent.verticalCenter
                        MouseArea { id: tMA; anchors.fill: parent; hoverEnabled: true }
                        Behavior on opacity { NumberAnimation { duration: 150 } } } }
                Rectangle { width: 1; height: 20; color: "#1e1e2e"; anchors.verticalCenter: parent.verticalCenter }
                Column { anchors.verticalCenter: parent.verticalCenter; spacing: 0
                    Text { text: root.clockTime; color: "#cdd6f4"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: root.dateStr; color: "#6c7086"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
        }
    }

    // ===== DESKTOP =====
    GridView {
        id: iconGrid; anchors.fill: parent; anchors.margins: 32; anchors.bottomMargin: 56
        cellWidth: 96; cellHeight: 110; z: 1; model: root.desktopFiles.length
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }

        delegate: Item {
            width: 96; height: 110
            property var fileData: root.desktopFiles[index]
            property bool isDir: fileData ? fileData.isDir === 1 : false
            property string fName: fileData ? fileData.name : ""
            property string fIcon: extIcon(fName, isDir)
            property string fColor: extColor(fName, isDir)

            Rectangle {
                anchors.fill: parent; anchors.margins: 8
                color: dMA.containsMouse ? "#1e1e2e" : "transparent"; radius: 12
                Behavior on color { ColorAnimation { duration: 120 } }
                scale: dMA.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Column { anchors.centerIn: parent; spacing: 6
                    Rectangle { width: 44; height: 44; radius: 11; anchors.horizontalCenter: parent.horizontalCenter
                        color: Qt.rgba(parseColor(fColor).r, parseColor(fColor).g, parseColor(fColor).b, 0.12)
                        Text { anchors.centerIn: parent; text: fIcon; font.pixelSize: 20 } }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: fName; color: "#a1a1aa"; font.pixelSize: 10; width: 80; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
                }
                MouseArea { id: dMA; anchors.fill: parent; hoverEnabled: true; onDoubleClicked: console.log("Open:", fName) }
            }
        }
    }

    // ===== START MENU =====
    Rectangle {
        id: startMenu; visible: root.showStartMenu; width: 440; height: 540
        x: 0; y: root.height - panel.height - height - 8
        color: "#14141e"; border.color: "#2a2a3c"; border.width: 1; radius: 16; z: 200
        opacity: root.showStartMenu ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 14
            Rectangle {
                Layout.fillWidth: true; height: 38; radius: 10; color: "#1e1e2e"; border.color: sI.activeFocus ? "#89b4fa" : "#2a2a3c"; border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }
                TextInput { id: sI; anchors.verticalCenter: parent.verticalCenter; x: 12; width: parent.width - 24; color: "#cdd6f4"; font.pixelSize: 13; clip: true
                    Text { text: "Search apps..."; color: "#45475a"; font.pixelSize: 13; visible: !sI.text && !sI.activeFocus; anchors.verticalCenter: parent.verticalCenter } }
            }
            Row { spacing: 6
                Repeater { model: ["All", "Frequent", "System", "Dev"]
                    delegate: Rectangle {
                        width: cT.width + 16; height: 24; radius: 12
                        color: index === 0 ? "#89b4fa" : "#1e1e2e"; border.color: "#2a2a3c"; border.width: index === 0 ? 0 : 1
                        Text { id: cT; anchors.centerIn: parent; text: modelData; color: index === 0 ? "#0c0c14" : "#6c7086"; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; hoverEnabled: true } } }

            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"
                GridView {
                    anchors.fill: parent; cellWidth: 88; cellHeight: 88; clip: true; model: root.apps.length
                    add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
                    delegate: Item {
                        width: 88; height: 88
                        property var appData: root.apps[index]

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 6
                            color: aMA.containsMouse ? "#1e1e2e" : "transparent"; radius: 10
                            Behavior on color { ColorAnimation { duration: 100 } }
                            scale: aMA.containsMouse ? 1.08 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                            Column { anchors.centerIn: parent; spacing: 5
                                Rectangle {
                                    width: 36; height: 36; radius: 9; anchors.horizontalCenter: parent.horizontalCenter
                                    color: aMA.containsMouse ? Qt.rgba(0.54, 0.71, 0.98, 0.15) : "#1e1e2e"
                                    // Use real icon if available, fallback to emoji
                                    Image {
                                        anchors.centerIn: parent
                                        width: 24; height: 24
                                        source: appData && appData.iconPath ? "file://" + appData.iconPath : ""
                                        sourceSize: Qt.size(24, 24)
                                        visible: status === Image.Ready
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: appData ? appIcon(appData.name) : "\u{1F4E6}"
                                        font.pixelSize: 16
                                        visible: !parent.children[0].visible
                                    }
                                }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: appData ? appData.name : ""; color: "#a1a1aa"; font.pixelSize: 10; width: 76; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
                            }
                            MouseArea { id: aMA; anchors.fill: parent; hoverEnabled: true; onClicked: root.showStartMenu = false }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e2e" }

            Row { Layout.fillWidth: true; spacing: 12
                Row { spacing: 10
                    Rectangle { width: 30; height: 30; radius: 15; color: "#1e1e2e"; border.color: "#89b4fa"; border.width: 1
                        Text { anchors.centerIn: parent; text: "A"; color: "#89b4fa"; font.pixelSize: 13; font.bold: true } }
                    Column { anchors.verticalCenter: parent.verticalCenter
                        Text { text: "admin"; color: "#cdd6f4"; font.pixelSize: 12; font.bold: true }
                        Text { text: "Logged in"; color: "#6c7086"; font.pixelSize: 10 } }
                }
                Item { Layout.fillWidth: true }
                Rectangle { width: 34; height: 34; radius: 8; color: pwrMA.containsMouse ? "#f38ba8" : "#1e1e2e"; border.color: "#2a2a3c"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "\u23FB"; color: pwrMA.containsMouse ? "#0c0c14" : "#f38ba8"; font.pixelSize: 15 }
                    MouseArea { id: pwrMA; anchors.fill: parent; hoverEnabled: true; onClicked: root.showPowerMenu = !root.showPowerMenu } }
            }
        }

        Rectangle {
            visible: root.showPowerMenu; width: 150; height: 110
            x: parent.width - width - 20; y: parent.height - height - 65
            color: "#1e1e2e"; border.color: "#2a2a3c"; border.width: 1; radius: 10; z: 10
            opacity: root.showPowerMenu ? 1.0 : 0.0; Behavior on opacity { NumberAnimation { duration: 120 } }
            Column {
                anchors.fill: parent; anchors.margins: 6; spacing: 2
                Repeater {
                    model: [
                        { icon: "\u{1F512}", label: "Lock", clr: "#89b4fa" },
                        { icon: "\u21BA", label: "Restart", clr: "#89b4fa" },
                        { icon: "\u23FB", label: "Power Off", clr: "#f38ba8" }
                    ]
                    delegate: Rectangle {
                        width: parent.width; height: 30; radius: 6
                        color: piMA.containsMouse ? modelData.clr : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Row {
                            anchors.fill: parent; anchors.margins: 8; spacing: 8
                            Text { text: modelData.icon; font.pixelSize: 11; color: piMA.containsMouse ? "#0c0c14" : "#6c7086"; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: modelData.label; font.pixelSize: 11; color: piMA.containsMouse ? "#0c0c14" : "#cdd6f4"; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: piMA; anchors.fill: parent; hoverEnabled: true; onClicked: root.showPowerMenu = false }
                    }
                }
            }
        }
    }

    MouseArea { anchors.fill: parent; z: 0; onClicked: { root.showStartMenu = false; root.showPowerMenu = false } }
    Shortcut { sequence: "Escape"; onActivated: { root.showStartMenu = false; root.showPowerMenu = false } }
    Shortcut { sequence: "Super"; onActivated: root.showStartMenu = !root.showStartMenu }
    Shortcut { sequence: "Alt+F4"; onActivated: Qt.quit() }
}
