import "CompatUi" as ThemeUi
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import qs.Commons as Commons
import qs.Ui
import "." as Local

BarWidget {
    id: root
    moduleName: "io.github.manateelazycat.workspace-gallery"

    property bool menuOpen: false
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function close() { root.menuOpen = false }

    function syncSetting() {
        Local.GlobalStates.closeWindowSwitchWorkspace =
            root.setting("closeWindowSwitchWorkspace", false) === true;
    }

    function selectMode(enabled) {
        const entry = Object.assign({}, root.settings ?? {}, {
            id: root.moduleName,
            closeWindowSwitchWorkspace: enabled
        });
        Local.GlobalStates.closeWindowSwitchWorkspace = enabled;
        root.settings = entry;
        if (root.bar?.shell?.updateEntryInline)
            root.bar.shell.updateEntryInline(root.moduleName, entry);
        root.close();
    }

    Component.onCompleted: root.syncSetting()
    onSettingsChanged: root.syncSetting()

    ThemeUi.BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        iconComponent: Component {
            GalleryIcon {
                color: button.active && button.useActiveColor ? button.activeColor : button.foreground
            }
        }
        active: root.menuOpen
        tooltipText: "工作区总览 · 右键设置关闭窗口行为"
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.LeftButton)
                Hyprland.dispatch('hl.dsp.global("quickshell:workspaceGalleryToggle")');
            else if (buttonCode === Qt.RightButton)
                root.menuOpen = !root.menuOpen;
        }
    }

    ThemeUi.PopupCard {
        id: menu
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.menuOpen
        padding: Commons.Style.space(8)
        contentWidth: menu.fittedContentWidth(Commons.Style.space(240))
        contentHeight: menu.fittedContentHeight(choices.implicitHeight)

        Column {
            id: choices
            anchors.fill: parent
            spacing: Commons.Style.space(2)

            Repeater {
                model: [
                    { label: "默认", enabled: false },
                    { label: "关闭窗口切换工作区", enabled: true }
                ]

                Rectangle {
                    id: choice
                    required property var modelData
                    readonly property bool selected:
                        Local.GlobalStates.closeWindowSwitchWorkspace === choice.modelData.enabled
                    width: choices.width
                    height: Commons.Style.space(34)
                    radius: Math.max(2, Commons.Style.cornerRadius)
                    color: choiceMouse.containsMouse || choice.selected
                        ? Commons.Style.hoverFillFor(Commons.Color.popups.text, Commons.Color.accent)
                        : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: Commons.Style.space(10)
                        anchors.verticalCenter: parent.verticalCenter
                        text: choice.modelData.label
                        color: Commons.Color.popups.text
                        font.family: root.bar ? root.bar.fontFamily : Commons.Style.font.family
                        font.pixelSize: Commons.Style.font.body
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: Commons.Style.space(10)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✓"
                        visible: choice.selected
                        color: Commons.Color.accent
                        font.family: root.bar ? root.bar.fontFamily : Commons.Style.font.family
                        font.pixelSize: Commons.Style.font.body
                    }

                    MouseArea {
                        id: choiceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectMode(choice.modelData.enabled)
                    }
                }
            }
        }
    }
}
