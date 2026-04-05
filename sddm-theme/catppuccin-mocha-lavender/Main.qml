import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height

    // Catppuccin Mocha Lavender palette (matches hyprlock: bg = #1e2030)
    readonly property color colBase:     "#1e2030"
    readonly property color colSurface0: "#363a4f"
    readonly property color colSurface1: "#494d64"
    readonly property color colOverlay0: "#6e738d"
    readonly property color colText:     "#cad3f5"
    readonly property color colSubtext1: "#b8c0e0"
    readonly property color colLavender: "#b7bdf8"
    readonly property color colRed:      "#ed8796"
    readonly property color colGreen:    "#a6da95"

    color: colBase

    // ─── Clock ───────────────────────────────────────────────────────────────

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -160
        spacing: 4

        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(new Date(), "HH:mm")
            color: colText
            font.pixelSize: 80
            font.family: "CaskaydiaCove Nerd Font"
            font.weight: Font.Light

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: timeLabel.text = Qt.formatTime(new Date(), "HH:mm")
            }
        }

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            color: colSubtext1
            font.pixelSize: 18
            font.family: "CaskaydiaCove Nerd Font"

            Timer {
                interval: 60000
                running: true
                repeat: true
                onTriggered: dateLabel.text = Qt.formatDate(new Date(), "dddd, MMMM d")
            }
        }
    }

    // ─── Login area ──────────────────────────────────────────────────────────

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 80
        spacing: 16

        // Welcome label (mirrors hyprlock: "Welcome back $USER")
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Welcome back " + (userModel.lastUser !== "" ? userModel.lastUser : sddm.hostName)
            color: colText
            font.pixelSize: 25
            font.family: "CaskaydiaCove Nerd Font"
        }

        // Password input field (mirrors hyprlock input-field: size 200x50)
        Rectangle {
            id: inputContainer
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: 50
            radius: 6
            color: colSurface0
            border.color: passwordInput.activeFocus ? colLavender : colOverlay0
            border.width: 2

            TextInput {
                id: passwordInput
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 14
                    rightMargin: 14
                }
                echoMode: TextInput.Password
                color: colText
                font.pixelSize: 16
                font.family: "CaskaydiaCove Nerd Font"
                selectionColor: colLavender
                selectedTextColor: colBase
                focus: true

                Keys.onReturnPressed: {
                    statusText.text = ""
                    statusText.color = colSubtext1
                    sddm.login(userModel.lastUser, passwordInput.text, sessionBox.currentIndex)
                }

                // Placeholder text
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !passwordInput.text
                    text: "Password..."
                    color: colOverlay0
                    font.pixelSize: 16
                    font.family: "CaskaydiaCove Nerd Font"
                    font.italic: true
                }
            }
        }

        // Status / error message (mirrors hyprlock fingerprint label position)
        Text {
            id: statusText
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            color: colSubtext1
            font.pixelSize: 14
            font.family: "CaskaydiaCove Nerd Font"
        }
    }

    // ─── SDDM signals ────────────────────────────────────────────────────────

    Connections {
        target: sddm

        function onLoginSucceeded() {
            statusText.text = ""
        }

        function onLoginFailed() {
            statusText.text = "Authentication failed"
            statusText.color = colRed
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        }
    }

    // ─── Session selector (bottom-left) ──────────────────────────────────────

    ComboBox {
        id: sessionBox
        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: 24
        }
        width: 180
        height: 34
        model: sessionModel
        currentIndex: sessionModel.lastIndex

        contentItem: Text {
            leftPadding: 10
            text: sessionBox.displayText
            color: colSubtext1
            font.pixelSize: 13
            font.family: "CaskaydiaCove Nerd Font"
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: "transparent"
            border.color: colOverlay0
            border.width: 1
            radius: 4
        }

        delegate: ItemDelegate {
            width: sessionBox.width
            contentItem: Text {
                text: modelData
                color: colText
                font.pixelSize: 13
                font.family: "CaskaydiaCove Nerd Font"
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: highlighted ? colSurface1 : colSurface0
            }
        }

        popup: Popup {
            y: sessionBox.height + 2
            width: sessionBox.width
            padding: 0
            contentItem: ListView {
                implicitHeight: contentHeight
                model: sessionBox.delegateModel
                clip: true
            }
            background: Rectangle {
                color: colSurface0
                border.color: colOverlay0
                border.width: 1
                radius: 4
            }
        }
    }

    // ─── Power buttons (bottom-right) ────────────────────────────────────────

    Row {
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 24
        }
        spacing: 10

        Repeater {
            model: [
                { icon: "⏾",  action: "suspend",   visible: sddm.canSuspend  },
                { icon: "⟳",  action: "reboot",    visible: sddm.canReboot   },
                { icon: "⏻",  action: "powerOff",  visible: sddm.canPowerOff }
            ]

            delegate: Rectangle {
                width: 38
                height: 38
                radius: 19
                visible: modelData.visible
                color: mouseArea.containsMouse ? colSurface1 : "transparent"
                border.color: mouseArea.containsMouse ? colLavender : colOverlay0
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    color: mouseArea.containsMouse ? colLavender : colSubtext1
                    font.pixelSize: 16

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.action === "suspend")   sddm.suspend()
                        else if (modelData.action === "reboot")   sddm.reboot()
                        else if (modelData.action === "powerOff") sddm.powerOff()
                    }
                }
            }
        }
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
