pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import CxOS.Config
import qs.components
import qs.components.containers
import qs.components.effects
import qs.services
import qs.utils

// Windows 11-style taskbar: centered start button, pinned/running apps, tray, quick settings and clock.
StyledWindow {
    id: root

    readonly property ScreenState screenState: ShellState.forScreen(screen)
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool hasFullscreen: monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property int barHeight: 48

    readonly property list<string> pinned: GlobalConfig.launcher.favouriteApps.length > 0 ? GlobalConfig.launcher.favouriteApps : ["thunar", "firefox", "foot", "org.pulseaudio.pavucontrol"]

    readonly property var windows: Hypr.toplevels.values.filter(t => t.lastIpcObject?.class && (t.monitor === monitor || t.workspace?.name === "special:minimized"))

    // One entry per app: pinned apps first (in order), then running apps that aren't pinned
    readonly property var apps: {
        const result = [];
        const seen = new Set();
        const keyFor = c => (DesktopEntries.heuristicLookup(c)?.id ?? c).toLowerCase().replace(/\.desktop$/, "");
        for (const id of pinned) {
            const key = keyFor(id);
            if (seen.has(key))
                continue;
            seen.add(key);
            result.push({
                key,
                id,
                windows: windows.filter(w => keyFor(w.lastIpcObject.class) === key)
            });
        }
        for (const w of windows) {
            const key = keyFor(w.lastIpcObject.class);
            if (seen.has(key))
                continue;
            seen.add(key);
            result.push({
                key,
                id: w.lastIpcObject.class,
                windows: windows.filter(x => keyFor(x.lastIpcObject.class) === key)
            });
        }
        return result;
    }

    function dispatchWin(lua: string, legacy: string): void {
        Hypr.dispatch(Hypr.usingLua ? lua : legacy);
    }

    function toggleWindow(w: HyprlandToplevel): void {
        const addr = `address:0x${w.address}`;
        if (w.workspace?.name === "special:minimized") {
            const ws = monitor?.activeWorkspace?.id ?? Hypr.activeWsId;
            dispatchWin(`hl.dsp.window.move({ window = "${addr}", workspace = "${ws}", follow = true })`, `movetoworkspace ${ws},${addr}`);
        } else if (w.activated) {
            // Minimise: park the window on a hidden special workspace
            dispatchWin(`hl.dsp.window.move({ window = "${addr}", workspace = "special:minimized", follow = false })`, `movetoworkspacesilent special:minimized,${addr}`);
        } else {
            dispatchWin(`hl.dsp.focus({ window = "${addr}" })`, `focuswindow ${addr}`);
        }
    }

    function launch(id: string): void {
        const entry = DesktopEntries.heuristicLookup(id);
        const cmd = entry ? entry.command : [id];
        Quickshell.execDetached(["systemd-run", "--user", "--scope", "--quiet", "--collect", "--slice=app-graphical.slice", "--", ...cmd]);
    }

    function toggleDrawer(name: string): void {
        const s = screenState;
        const open = !s[name];
        s.launcher = false;
        s.sidebar = false;
        s.dashboard = false;
        s.utilities = false;
        s[name] = open;
    }

    name: "taskbar"
    visible: !hasFullscreen
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    implicitHeight: barHeight
    exclusiveZone: barHeight
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3surfaceContainer, 0.92)

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.alpha(Colours.palette.m3outlineVariant, 0.6)
        }
    }

    // Left: weather / workspace indicator
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        TaskButton {
            icon: "space_dashboard"
            tooltip: qsTr("Visão de tarefas")
            onClicked: root.toggleDrawer("dashboard")
        }

        StyledText {
            text: qsTr("Área %1").arg(root.monitor?.activeWorkspace?.id ?? 1)
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: 10
        }
    }

    // Center: start, search and apps
    Row {
        id: center

        anchors.centerIn: parent
        spacing: 4

        TaskButton {
            id: startButton

            active: root.screenState?.launcher ?? false
            tooltip: qsTr("Iniciar")
            onClicked: root.toggleDrawer("launcher")

            Logo {
                anchors.centerIn: parent
                width: 24
                height: 24
            }
        }

        TaskButton {
            icon: "search"
            tooltip: qsTr("Pesquisar")
            onClicked: root.toggleDrawer("launcher")
        }

        Repeater {
            model: ScriptModel {
                values: root.apps
                objectProp: "key"
            }

            TaskButton {
                id: appButton

                required property var modelData
                readonly property var wins: modelData.windows
                readonly property bool running: wins.length > 0
                readonly property bool focused: wins.some(w => w.activated)

                active: focused
                tooltip: DesktopEntries.heuristicLookup(modelData.id)?.name ?? modelData.id
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: event => {
                    if (event.button === Qt.MiddleButton || !running)
                        root.launch(modelData.id);
                    else if (event.button === Qt.RightButton)
                        for (const w of wins)
                            root.dispatchWin(`hl.dsp.window.kill({ window = "address:0x${w.address}" })`, `closewindow address:0x${w.address}`);
                    else if (wins.length === 1 || focused)
                        root.toggleWindow(focused ? wins.find(w => w.activated) : wins[0]);
                    else
                        root.toggleWindow(wins[0]);
                }

                Image {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    sourceSize.width: 52
                    sourceSize.height: 52
                    asynchronous: true
                    // Re-evaluate once desktop entries finish loading
                    source: DesktopEntries.applications.values.length >= 0 ? Icons.getAppIcon(appButton.modelData.id, "application-x-executable") : ""
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: appButton.running
                    width: appButton.focused ? 16 : 6
                    height: 3
                    radius: 2
                    color: appButton.focused ? Colours.palette.m3primary : Colours.palette.m3outline

                    Behavior on width {
                        Anim {}
                    }
                }
            }
        }
    }

    // Right: tray, quick settings, clock, show desktop
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: ScriptModel {
                values: SystemTray.items.values.filter(i => i.status !== Status.Passive)
            }

            MouseArea {
                id: trayItem

                required property SystemTrayItem modelData

                implicitWidth: 28
                implicitHeight: 28
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: event => {
                    if (event.button === Qt.RightButton && modelData.hasMenu) {
                        const p = mapToItem(null, 0, 0);
                        modelData.display(root, p.x, p.y - 8);
                    } else {
                        modelData.activate();
                    }
                }

                ColouredIcon {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: Icons.getTrayIcon(trayItem.modelData.id, trayItem.modelData.icon)
                    colour: Colours.palette.m3onSurface
                }
            }
        }

        TaskButton {
            implicitWidth: quick.implicitWidth + 20
            active: root.screenState?.sidebar ?? false
            tooltip: qsTr("Configurações rápidas")
            onClicked: root.toggleDrawer("sidebar")

            Row {
                id: quick

                anchors.centerIn: parent
                spacing: 8

                MaterialIcon {
                    text: Nmcli.activeEthernet ? "lan" : Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                    color: Colours.palette.m3onSurface
                }
                MaterialIcon {
                    text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                    color: Colours.palette.m3onSurface
                }
                MaterialIcon {
                    visible: UPower.displayDevice.isLaptopBattery
                    text: Icons.getBatteryIcon(UPower.displayDevice.percentage * 100, UPower.displayDevice.state === UPowerDeviceState.Charging)
                    color: Colours.palette.m3onSurface
                }
            }
        }

        TaskButton {
            implicitWidth: clock.implicitWidth + 20
            active: root.screenState?.dashboard ?? false
            tooltip: Time.format("dddd, d 'de' MMMM 'de' yyyy")
            onClicked: root.toggleDrawer("dashboard")

            Column {
                id: clock

                anchors.centerIn: parent

                StyledText {
                    anchors.right: parent.right
                    text: Time.format("hh:mm")
                    color: Colours.palette.m3onSurface
                    font.pointSize: 10
                }
                StyledText {
                    anchors.right: parent.right
                    text: Time.format("dd/MM/yyyy")
                    color: Colours.palette.m3onSurface
                    font.pointSize: 9
                }
            }
        }

        // Show desktop sliver, like Windows
        MouseArea {
            implicitWidth: 8
            implicitHeight: root.barHeight
            hoverEnabled: true
            onClicked: Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("minimized")` : "togglespecialworkspace minimized")

            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: 20
                color: Colours.palette.m3outlineVariant
                visible: parent.containsMouse
            }
        }
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "taskbar"
        component: root
    }

    component TaskButton: MouseArea {
        id: btn

        property string icon
        property string tooltip
        property bool active

        implicitWidth: 44
        implicitHeight: 40
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: btn.active ? Qt.alpha(Colours.palette.m3onSurface, 0.12) : btn.containsMouse ? Qt.alpha(Colours.palette.m3onSurface, 0.08) : "transparent"

            Behavior on color {
                CAnim {}
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: btn.icon.length > 0
            text: btn.icon
            color: Colours.palette.m3onSurface
            fontStyle: Tokens.font.icon.large
        }

        StyledText {
            visible: btn.containsMouse && btn.tooltip.length > 0
            parent: btn
            anchors.bottom: btn.top
            anchors.bottomMargin: 6
            anchors.horizontalCenter: btn.horizontalCenter
            text: btn.tooltip
            color: Colours.palette.m3onSurface
            font.pointSize: 9
        }
    }
}
