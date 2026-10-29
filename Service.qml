import QtQuick
import Quickshell
import Quickshell.Hyprland
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

  // Built-in panel for the primary/external screen modes, found from monitor
  // names Quickshell already tracks (no external command). Hyprland's list
  // also covers a disabled built-in panel (lid closed), like `hyprctl monitors all`.
  readonly property string internalMonitorName: Clock.internalMonitorName(
    Quickshell.screens.map(function(s) { return s.name })
      .concat(Hyprland.monitors.values.map(function(m) { return m.name }))
  )
  readonly property string focusedMonitorName: Hyprland.focusedMonitor
    ? String(Hyprland.focusedMonitor.name || "")
    : ""

  readonly property string barPos: Clock.barPosition(shell)
  readonly property bool barVertical: Clock.barIsVertical(root.barPos, shell)
  readonly property int barClearance: Math.round(
    (root.barVertical ? Style.bar.sizeVertical : Style.bar.sizeHorizontal) + 14
  )
  readonly property var clockInsets: Clock.edgeInsets(
    root.cfg.position, root.barPos, root.barClearance, root.cfg.barPadding
  )

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

  // Full-screen surface path (compactSurface: false): the clock is laid out
  // inside a transparent surface covering the whole output.
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
    item.placedX = placed.x
    item.placedY = placed.y
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

      // Compact surface (default): the layer surface is only the clock plus its
      // click padding and the compositor places it via anchors + margins, so a
      // ring tick no longer repaints and recomposites a full-screen surface.
      // Padding shrinks against an anchored edge instead of letting a margin go
      // negative, and the surface never exceeds the output.
      readonly property bool compact: root.cfg.compactSurface !== false
      readonly property real hitPadX: Math.max(Style.space(28), (Style.space(180) - clockFace.implicitWidth) / 2)
      readonly property real hitPadY: Math.max(Style.space(28), (Style.space(180) - clockFace.implicitHeight) / 2)
      readonly property real edgeTop: root.cfg.margin + root.clockInsets.top
      readonly property real edgeBottom: root.cfg.margin + root.clockInsets.bottom
      readonly property real edgeLeft: root.cfg.margin + root.clockInsets.left
      readonly property real edgeRight: root.cfg.margin + root.clockInsets.right
      readonly property bool anchorTop: root.pos.verticalAlign === "top"
      readonly property bool anchorBottom: root.pos.verticalAlign === "bottom"
      readonly property bool anchorLeft: root.pos.edgeSide === "left"
      readonly property bool anchorRight: root.pos.edgeSide === "right"
      readonly property real padTop: panel.anchorTop ? Math.min(panel.hitPadY, panel.edgeTop) : panel.hitPadY
      readonly property real padBottom: panel.anchorBottom ? Math.min(panel.hitPadY, panel.edgeBottom) : panel.hitPadY
      readonly property real padLeft: panel.anchorLeft ? Math.min(panel.hitPadX, panel.edgeLeft) : panel.hitPadX
      readonly property real padRight: panel.anchorRight ? Math.min(panel.hitPadX, panel.edgeRight) : panel.hitPadX

      screen: modelData
      visible: clockVisible
      // Unanchored axes are centred by the compositor (middle / center positions).
      anchors {
        top: !panel.compact || panel.anchorTop
        bottom: !panel.compact || panel.anchorBottom
        left: !panel.compact || panel.anchorLeft
        right: !panel.compact || panel.anchorRight
      }
      margins {
        top: panel.compact && panel.anchorTop ? panel.edgeTop - panel.padTop : 0
        bottom: panel.compact && panel.anchorBottom ? panel.edgeBottom - panel.padBottom : 0
        left: panel.compact && panel.anchorLeft ? panel.edgeLeft - panel.padLeft : 0
        right: panel.compact && panel.anchorRight ? panel.edgeRight - panel.padRight : 0
      }
      implicitWidth: Math.min(modelData.width,
        Math.ceil(clockFace.implicitWidth + panel.padLeft + panel.padRight))
      implicitHeight: Math.min(modelData.height,
        Math.ceil(clockFace.implicitHeight + panel.padTop + panel.padBottom))
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

        // Written by root.placeClock() on the full-screen path.
        property real placedX: 0
        property real placedY: 0
        // Compact path: measured from the anchored edge (as placeClock does),
        // clamped the same way when the clock exceeds the output-capped surface.
        readonly property var compactPos: Clock.clampPlacement(
          panel.anchorRight ? panel.width - panel.padRight - clockHost.width
            : (panel.anchorLeft ? panel.padLeft : (panel.width - clockHost.width) / 2),
          panel.anchorBottom ? panel.height - panel.padBottom - clockHost.height
            : (panel.anchorTop ? panel.padTop : (panel.height - clockHost.height) / 2),
          clockHost.width, clockHost.height, panel.width, panel.height)
        x: panel.compact ? clockHost.compactPos.x : clockHost.placedX
        y: panel.compact ? clockHost.compactPos.y : clockHost.placedY

        function relayout() {
          if (!panel.compact)
            root.schedulePlaceClock(clockHost, panel)
        }

        Component.onCompleted: clockHost.relayout()

        Connections {
          target: panel
          function onWidthChanged() { clockHost.relayout() }
          function onHeightChanged() { clockHost.relayout() }
          function onClockVisibleChanged() { clockHost.relayout() }
          function onCompactChanged() { clockHost.relayout() }
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
          // Sized from the output: a compact surface is only as big as the clock.
          availableWidth: modelData.width
          availableHeight: modelData.height
          screenMargin: root.cfg.margin
          screenInsets: root.clockInsets
          scaleFactor: root.scaleForScreen(modelData.height)
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
          lowPower: root.cfg.lowPower
          renderer: root.cfg.renderer
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
          // Compact: the whole surface is the hit target (it is the padded clock).
          width: panel.compact ? panel.width : Math.max(clockHost.width + Style.space(56), Style.space(180))
          height: panel.compact ? panel.height : Math.max(clockHost.height + Style.space(56), Style.space(180))
          x: panel.compact ? -clockHost.x : (clockHost.width - width) / 2
          y: panel.compact ? -clockHost.y : (clockHost.height - height) / 2
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
