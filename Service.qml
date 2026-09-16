import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "ClockModel.js" as Clock
import "PluginConfig.js" as Config

Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginId: manifest && manifest.id ? manifest.id : "mash2rafi.kronos"
  readonly property var pluginEntry: liveConfig.entry || Config.entryOrDefault(shell, root.pluginId)
  readonly property var cfg: Clock.readSettings(root.pluginEntry)

  ShellConfigWatcher {
    id: liveConfig
    pluginId: root.pluginId
  }
  readonly property var pos: Clock.parsePosition(root.cfg.position)

  property string internalMonitorName: ""
  readonly property string focusedMonitorName: Hyprland.focusedMonitor
    ? String(Hyprland.focusedMonitor.name || "")
    : ""

  readonly property string barPos: Clock.barPosition(shell)
  readonly property bool barVertical: Clock.barIsVertical(root.barPos, shell)
  readonly property int barClearance: Math.round(
    (root.barVertical ? Style.bar.sizeVertical : Style.bar.sizeHorizontal) + 14
  )
  readonly property var clockInsets: Clock.edgeInsets(
    root.cfg.position, root.barPos, root.barVertical, root.barClearance, root.cfg.barPadding
  )

  readonly property int monitorStateStdoutCap: 256
  readonly property int monitorStateTimeoutMs: 5000

  function refreshMonitorNames() {
    if (monitorStateProc.running) return
    monitorStateProc.running = true
    monitorStateTimeout.restart()
  }

  function finishMonitorStatePoll() {
    monitorStateTimeout.stop()
  }

  function shouldShowOnScreen(screen) {
    return Clock.shouldShowOnScreen(
      screen,
      root.cfg.screenMode,
      root.internalMonitorName,
      root.focusedMonitorName,
      root.cfg.selectedMonitors
    )
  }

  function scaleForScreen(screenHeight) {
    return Clock.perMonitorScaleFactor(
      root.cfg.scale,
      screenHeight,
      root.cfg.perMonitorScale,
      root.cfg.scaleReferenceHeight
    )
  }

  function openSettings() {
    if (root.shell && typeof root.shell.summon === "function")
      root.shell.summon(root.pluginId, "{}")
  }

  function placeClock(item, panel) {
    if (!item || !panel || panel.width <= 0 || panel.height <= 0) return

    var margin = root.cfg.margin
    var inset = root.clockInsets
    var top = margin + inset.top
    var right = margin + inset.right
    var bottom = margin + inset.bottom
    var left = margin + inset.left
    var x = 0
    var y = 0

    if (root.pos.verticalAlign === "top") {
      y = top
    } else if (root.pos.verticalAlign === "bottom") {
      y = panel.height - item.height - bottom
    } else {
      y = (panel.height - item.height) / 2
    }

    if (root.pos.edgeSide === "center") {
      x = (panel.width - item.width) / 2
    } else if (root.pos.edgeSide === "right") {
      x = panel.width - item.width - right
    } else {
      x = left
    }

    var placed = Clock.clampPlacement(x, y, item.width, item.height, panel.width, panel.height)
    item.x = placed.x
    item.y = placed.y
  }

  function schedulePlaceClock(item, panel) {
    placeDebounce.host = item
    placeDebounce.panel = panel
    placeDebounce.restart()
  }

  Timer {
    id: placeDebounce
    interval: 1
    repeat: false
    property var host: null
    property var panel: null
    onTriggered: root.placeClock(host, panel)
  }

  Component.onCompleted: {
    if (Clock.needsInternalMonitorName(root.cfg.screenMode))
      root.refreshMonitorNames()
  }

  Timer {
    interval: 5000
    running: Clock.needsInternalMonitorName(root.cfg.screenMode)
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshMonitorNames()
  }

  Timer {
    id: monitorStateTimeout
    interval: root.monitorStateTimeoutMs
    repeat: false
    onTriggered: {
      if (monitorStateProc.running)
        monitorStateProc.running = false
    }
  }

  Process {
    id: monitorStateProc
    // Extract internal monitor name (line 2) and cap stdout before StdioCollector.
    command: [
      "sh", "-c",
      "omarchy-monitor-state 2>/dev/null | sed -n '2p' | head -c " + root.monitorStateStdoutCap
    ]
    onExited: root.finishMonitorStatePoll()
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.internalMonitorName = String(text || "").trim()
        root.finishMonitorStatePoll()
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData

      readonly property bool screenActive: Clock.screenReady(modelData)
      readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
      readonly property real screenRefreshRate: Clock.refreshRateForMonitor(hyprMonitor)
      readonly property bool clockVisible: screenActive
        && root.cfg.clockEnabled !== false
        && root.shouldShowOnScreen(modelData)
        && !remapGuard.remapping

      screen: modelData
      visible: clockVisible
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      updatesEnabled: clockVisible

      ScreenMoveRemap {
        id: remapGuard
        window: panel
      }

      WlrLayershell.namespace: "MASH2RAFI-kronos"
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      Item {
        id: clockHost
        visible: panel.clockVisible
        width: clockFace.implicitWidth
        height: clockFace.implicitHeight

        function relayout() {
          root.schedulePlaceClock(clockHost, panel)
        }

        Component.onCompleted: clockHost.relayout()

        Connections {
          target: panel
          function onWidthChanged() { clockHost.relayout() }
          function onHeightChanged() { clockHost.relayout() }
          function onClockVisibleChanged() { clockHost.relayout() }
        }

        Connections {
          target: modelData
          enabled: modelData !== null && modelData !== undefined
          function onWidthChanged() { clockHost.relayout() }
          function onHeightChanged() { clockHost.relayout() }
        }

        Connections {
          target: root
          function onPluginEntryChanged() { clockHost.relayout() }
          function onClockInsetsChanged() { clockHost.relayout() }
          function onFocusedMonitorNameChanged() { clockHost.relayout() }
          function onInternalMonitorNameChanged() { clockHost.relayout() }
        }

        Connections {
          target: shell
          function onBarConfigChanged() { clockHost.relayout() }
        }

        Connections {
          target: clockFace
          function onImplicitWidthChanged() { clockHost.relayout() }
          function onImplicitHeightChanged() { clockHost.relayout() }
        }

        ClockFace {
          id: clockFace
          width: clockFace.implicitWidth
          height: clockFace.implicitHeight
          active: panel.clockVisible
          availableWidth: panel.width
          availableHeight: panel.height
          screenMargin: root.cfg.margin
          screenInsets: root.clockInsets
          scaleFactor: root.scaleForScreen(panel.height)
          hourScaleFactor: root.cfg.hourScale
          dateScaleFactor: root.cfg.dateScale
          subtimeScaleFactor: root.cfg.subtimeScale
          ringLabelScaleFactor: root.cfg.ringLabelScale
          minuteCapsuleScaleFactor: root.cfg.minuteCapsuleScale
          secondCapsuleScaleFactor: root.cfg.secondCapsuleScale
          screenRefreshRate: panel.screenRefreshRate
          position: root.cfg.position
          use24h: root.cfg.use24h
          showSeconds: root.cfg.showSeconds
          showDate: root.cfg.showDate
          accentMode: root.cfg.accentMode
          clockFont: root.cfg.clockFont
          labelFont: root.cfg.labelFont
          centerLayout: root.cfg.centerLayout
          ringDiameter: root.cfg.ringDiameter
          ringGap: root.cfg.ringGap
          ringArcDegrees: root.cfg.ringArcDegrees
          ringTransparency: root.cfg.ringTransparency
          hourColor: root.cfg.hourColor
          dateColor: root.cfg.dateColor
          minuteCapsuleColor: root.cfg.minuteCapsuleColor
          secondCapsuleColor: root.cfg.secondCapsuleColor
          minuteRingColor: root.cfg.minuteRingColor
          secondRingColor: root.cfg.secondRingColor
          ringLabelColor: root.cfg.ringLabelColor
          hourFont: root.cfg.hourFont
          dateFont: root.cfg.dateFont
          minuteCapsuleFont: root.cfg.minuteCapsuleFont
          secondCapsuleFont: root.cfg.secondCapsuleFont
          showHour: root.cfg.showHour
          showMinuteCapsule: root.cfg.showMinuteCapsule
          showSecondCapsule: root.cfg.showSecondCapsule
          showRingLabels: root.cfg.showRingLabels
          showRings: root.cfg.showRings
          hourOffsetX: root.cfg.hourOffsetX
          hourOffsetY: root.cfg.hourOffsetY
          dateOffsetX: root.cfg.dateOffsetX
          dateOffsetY: root.cfg.dateOffsetY
          minuteCapsuleAngleOffset: root.cfg.minuteCapsuleAngleOffset
          secondCapsuleAngleOffset: root.cfg.secondCapsuleAngleOffset
          minuteCapsuleRadiusOffset: root.cfg.minuteCapsuleRadiusOffset
          secondCapsuleRadiusOffset: root.cfg.secondCapsuleRadiusOffset
          ringRotationOffset: root.cfg.ringRotationOffset
        }

        // Larger hit target — the clock chrome is often small (corners, minimal layout).
        MouseArea {
          z: 20
          anchors.centerIn: parent
          width: Math.max(clockHost.width + Style.space(56), Style.space(180))
          height: Math.max(clockHost.height + Style.space(56), Style.space(180))
          acceptedButtons: Qt.RightButton | Qt.LeftButton
          hoverEnabled: false
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton)
              root.openSettings()
          }
          onDoubleClicked: root.openSettings()
        }
      }
    }
  }
}
