import QtQuick
import qs.Commons
import "ClockModel.js" as Clock
import "ClockTheme.js" as Theme

Item {
  id: face
  clip: false

  property bool active: true
  property bool use24h: true
  property bool showSeconds: true
  property bool showDate: true
  property real scaleFactor: 1
  property real hourScaleFactor: 1
  property real dateScaleFactor: 1
  property real subtimeScaleFactor: 1
  property real ringLabelScaleFactor: 1
  property real minuteCapsuleScaleFactor: 1
  property real secondCapsuleScaleFactor: 1
  property real availableHeight: 0
  property real availableWidth: 0
  property int screenMargin: 0
  property var screenInsets: ({ top: 0, right: 0, bottom: 0, left: 0 })
  property string position: "middle-right"
  property string centerLayout: "orbit"
  property string clockFont: "Liberation Sans"
  property string labelFont: "JetBrainsMono Nerd Font,JetBrainsMono NF"
  property real ringDiameter: 0.40
  property real ringGap: 48
  property int ringArcDegrees: 180
  property real ringTransparency: 1
  property string accentMode: "contrast"
  property bool lowPower: false
  property string renderer: "shader"
  property real screenRefreshRate: 60

  property string hourColor: ""
  property string dateColor: ""
  property string minuteCapsuleColor: ""
  property string secondCapsuleColor: ""
  property string minuteRingColor: ""
  property string secondRingColor: ""
  property string ringLabelColor: ""
  property string hourFont: ""
  property string dateFont: ""
  property string minuteCapsuleFont: ""
  property string secondCapsuleFont: ""
  property bool showHour: true
  property bool showMinuteCapsule: true
  property bool showSecondCapsule: true
  property bool showRingLabels: true
  property bool showRings: true
  property real hourOffsetX: 0
  property real hourOffsetY: 0
  property real dateOffsetX: 0
  property real dateOffsetY: 0
  property real minuteCapsuleAngleOffset: 0
  property real secondCapsuleAngleOffset: 0
  property real minuteCapsuleRadiusOffset: 0
  property real secondCapsuleRadiusOffset: 0
  property real ringRotationOffset: 0

  readonly property string effectiveHourFont: face.hourFont !== "" ? face.hourFont : face.clockFont
  readonly property string effectiveDateFont: face.dateFont !== "" ? face.dateFont : face.clockFont
  readonly property string effectiveDateLabelFont: face.dateFont !== "" ? face.dateFont : face.labelFont
  readonly property string effectiveMinuteCapsuleFont: face.minuteCapsuleFont !== "" ? face.minuteCapsuleFont : face.clockFont
  readonly property string effectiveSecondCapsuleFont: face.secondCapsuleFont !== "" ? face.secondCapsuleFont : face.clockFont
  readonly property real ringRotationOffsetRad: face.ringRotationOffset * Math.PI / 180
  readonly property real minuteCapsuleAngleOffsetRad: face.minuteCapsuleAngleOffset * Math.PI / 180
  readonly property real secondCapsuleAngleOffsetRad: face.secondCapsuleAngleOffset * Math.PI / 180

  property real timeMs: Date.now()
  // Whole-second clock: text, date and the minute ring only change once a
  // second, so they bind to this instead of the fast ring tick.
  readonly property real secondMs: Math.floor(face.timeMs / 1000) * 1000

  readonly property bool ringsVisible: face.showRings && face.spec.showRings !== false
  // With no rings to animate (e.g. digital layout) only text changes, so a
  // quarter-second tick keeps the seconds readout on time without 60 Hz work.
  readonly property int ringTickMs: face.ringsVisible
    ? Clock.tickIntervalMs(face.screenRefreshRate, face.lowPower, face.showSeconds)
    : (face.showSeconds ? 250 : 1000)
  readonly property real layoutScale: Clock.clampScale(face.scaleFactor)
  readonly property real hourScale: Clock.clampTextScale(face.hourScaleFactor)
  readonly property real dateScale: Clock.clampTextScale(face.dateScaleFactor)
  readonly property real subtimeScale: Clock.clampTextScale(face.subtimeScaleFactor)
  readonly property real ringLabelScale: Clock.clampTextScale(face.ringLabelScaleFactor)
  readonly property real minuteCapsuleScale: Clock.clampTextScale(face.minuteCapsuleScaleFactor)
  readonly property real secondCapsuleScale: Clock.clampTextScale(face.secondCapsuleScaleFactor)
  readonly property var now: Clock.partsAt(face.secondMs, face.use24h)
  readonly property var spec: Clock.layoutSpec(face.position, face.centerLayout, face.ringArcDegrees)
  readonly property bool fullRing: face.spec.fullRing
  readonly property real ringFocusAngle: face.spec.focusAngle
  readonly property var ringArc: Clock.resolvedArcBounds(face.spec)
  readonly property real labelPad: Math.round(12 * face.layoutScale)
  readonly property real ringLabelBleed: Math.round(22 * face.ringLabelScale)
  readonly property real verticalInset: Math.round(44 * face.layoutScale)
  readonly property real heightFit: Clock.clampRingDiameter(face.ringDiameter) * face.spec.dialSizeFactor
  readonly property real fitOuterRadius: Clock.fitOuterRadiusForPosition(
    face.availableWidth,
    face.availableHeight,
    face.heightFit,
    face.labelPad,
    face.verticalInset,
    face.position,
    face.screenMargin,
    face.screenInsets
  )
  readonly property real ringGapPx: Clock.clampRingGap(face.ringGap)
  readonly property real outerRadius: Math.max(80, face.fitOuterRadius)
  readonly property real minuteRadius: face.showSeconds
    ? Math.max(64, face.outerRadius - face.ringGapPx)
    : Math.max(64, face.outerRadius)
  readonly property real secondRadius: face.showSeconds ? face.outerRadius : face.minuteRadius
  readonly property real dialSize: Math.round(face.secondRadius * 2 + face.labelPad * 2)
  readonly property real hourSize: Clock.hourSizeFromScale(face.hourScale, face.spec.hourSizeFactor)
  readonly property real centerDateGap: Math.round(12 * face.dateScale)
  // The digital readout has no ring to size the dial, so its text blocks are
  // measured; orbit keeps the formula heights its ring layout is tuned for
  // (only the below-dial date, which sits outside the ring, is measured).
  readonly property bool measureText: face.spec.digitalReadout === true
  readonly property real centerDateH: face.showDate
    ? Math.max(Clock.centerDateBlockHeight(face.use24h, face.dateScale), centerDateBlock.implicitHeight)
    : 0
  readonly property real dateColumnH: Math.max(Clock.dateColumnHeight(face.use24h, face.dateScale),
    face.measureText ? Math.max(dateAboveCol.implicitHeight, dateBelowCol.implicitHeight) : 0)
  readonly property real subtimeH: Math.round(13 * face.subtimeScale)
  readonly property int columnSpacing: Math.round(7 * Math.max(face.hourScale, face.dateScale, face.subtimeScale))
  readonly property real hourOnlyH: Math.max(face.hourSize + Math.round(12 * face.hourScale),
    face.measureText ? digitalRow.implicitHeight : 0)
  readonly property real minuteCapsuleAngle: face.spec.singleCapsule
    ? face.spec.minuteCapsuleAngle
    : (face.spec.showCapsules ? face.spec.minuteCapsuleAngle : face.ringFocusAngle)
  readonly property real secondCapsuleAngle: face.spec.showCapsules && !face.spec.singleCapsule
    ? face.spec.secondCapsuleAngle
    : face.ringFocusAngle
  readonly property real hourW: Math.max(Math.round(face.hourSize * 0.78), hourColumn.implicitWidth)
  readonly property real hourH: face.hourOnlyH
  readonly property real minutePillWidth: Math.round(42 * face.minuteCapsuleScale)
  readonly property real secondPillWidth: Math.round(42 * face.secondCapsuleScale)
  readonly property var geo: Clock.clockGeometry(
    face.position,
    face.secondRadius,
    face.labelPad,
    face.hourW,
    face.hourOnlyH,
    face.showDate && face.spec.dateBelowDial,
    face.centerDateGap,
    face.centerDateH,
    face.ringLabelBleed,
    {
      dateInColumn: face.showDate && face.spec.dateInHourColumn,
      dateColumnH: face.dateColumnH,
      dateAboveHour: face.spec.dateAboveHour,
      showCenterSubtime: false,
      hourSize: face.measureText ? face.hourOnlyH : face.hourSize,
      columnSpacing: face.columnSpacing,
      subtimeH: face.subtimeH,
      // Digits have no descenders, so when the hour is the column's last line
      // most of its font descent is empty space. Keep ~4% of the size for
      // round-digit overshoot below the baseline and antialiasing.
      drawnColumnH: hourColumn.implicitHeight
        - (face.showDate && face.spec.dateInHourColumn && !face.spec.dateAboveHour
          ? 0 : Math.max(0, hourMetrics.descent - Math.ceil(face.hourSize * 0.04))),
      // Digital glyphs are heavy with negative tracking and overhang their
      // advance width by a few px, so reserve that as extra horizontal slack.
      nudgeX: Math.max(Math.abs(face.hourOffsetX),
        face.showDate && face.spec.dateInHourColumn ? Math.abs(face.dateOffsetX) : 0)
        + (face.measureText ? Math.round(4 * face.hourScale) : 0),
      nudgeY: Math.max(Math.abs(face.hourOffsetY),
        face.showDate && face.spec.dateInHourColumn ? Math.abs(face.dateOffsetY) : 0)
    }
  )
  readonly property real minuteProgress: Clock.minuteProgress(face.now)
  readonly property real secondProgress: Clock.secondProgressAt(face.timeMs)
  readonly property var colors: Theme.applyOverrides(Theme.palette(face.accentMode, {
    foreground: Color.foreground,
    background: Color.background,
    muted: Color.muted,
    accent: Color.accent
  }), {
    hour: face.hourColor,
    datePrimary: face.dateColor,
    minuteCapsuleText: face.minuteCapsuleColor,
    secondCapsuleText: face.secondCapsuleColor,
    minuteRing: face.minuteRingColor,
    secondRing: face.secondRingColor
  })
  readonly property color minuteRingLabelColor: face.ringLabelColor !== "" ? face.ringLabelColor : face.colors.minuteRing
  readonly property color secondRingLabelColor: face.ringLabelColor !== "" ? face.ringLabelColor : face.colors.secondRing
  readonly property real ringStrength: face.spec.ringStrength * face.ringTransparency
  readonly property var capsuleAngles: Clock.capsuleRenderAngles(
    face.minuteCapsuleAngle,
    face.secondCapsuleAngle,
    face.spec.singleCapsule
  )
  readonly property real minuteCapsuleRenderAngle: face.capsuleAngles.minute
  readonly property real secondCapsuleRenderAngle: face.capsuleAngles.second
  readonly property string subtimeText: face.showSeconds
    ? (face.now.mm + ":" + face.now.ss)
    : face.now.mm

  implicitWidth: Math.max(1, geo.width)
  implicitHeight: Math.max(1, geo.height)

  function themedInk(color, alpha) {
    return Theme.ink(color, alpha)
  }

  readonly property string minuteCapsuleText: face.spec.singleCapsule ? face.subtimeText : face.now.mm
  readonly property string secondCapsuleText: face.now.ss

  function capsulePoint(radius, angle) {
    return Qt.point(
      face.geo.dialX + face.geo.cx + Math.cos(angle) * radius,
      face.geo.dialY + face.geo.cy + Math.sin(angle) * radius
    )
  }

  function markRingDirty() {
    rings.repaint()
  }

  function refreshTime() {
    face.timeMs = Date.now()
    if (face.ringsVisible)
      rings.tick()
  }

  Timer {
    id: ringTick
    interval: face.ringTickMs
    running: face.active
    repeat: true
    triggeredOnStart: true
    onTriggered: face.refreshTime()
  }

  onRingTickMsChanged: ringTick.restart()
  onActiveChanged: if (face.active) ringTick.restart()

  FontMetrics {
    id: hourMetrics
    font: hourText.font
  }

  Item {
    id: dialBlock
    z: 1
    x: face.geo.dialX
    y: face.geo.dialY
    width: face.geo.dialW
    height: face.geo.dialH
    clip: false

    RingCanvas {
      id: rings
      visible: face.ringsVisible
      renderer: face.renderer
      width: parent.width
      height: face.geo.dialH
      cx: face.geo.cx
      cy: face.geo.cy
      minuteRadius: face.minuteRadius
      secondRadius: face.secondRadius
      minuteProgress: face.minuteProgress
      secondProgress: face.secondProgress
      focusAngle: face.ringFocusAngle + face.ringRotationOffsetRad
      fullRing: face.fullRing
      showSeconds: face.showSeconds
      ringStrength: face.ringStrength
      ringColor: face.colors.minuteRing
      secondRingColor: face.colors.secondRing
      minuteLabelColor: face.minuteRingLabelColor
      secondLabelColor: face.secondRingLabelColor
      showLabels: face.showRingLabels
      labelScale: face.ringLabelScale
      chromeScale: face.layoutScale
      labelFont: face.labelFont
      arcFrom: face.ringArc.from
      arcTo: face.ringArc.to
      showGuideRing: face.spec.showGuideRing
      arcEmphasis: face.spec.arcEmphasis === true
      arcEdgeFade: face.spec.arcEdgeFade
    }

    Connections {
      target: face
      function onGeoChanged() { face.markRingDirty() }
      function onSpecChanged() { face.markRingDirty() }
      function onColorsChanged() { face.markRingDirty() }
      function onRingStrengthChanged() { face.markRingDirty() }
      function onShowSecondsChanged() { face.markRingDirty() }
      function onLabelFontChanged() { face.markRingDirty() }
      function onShowRingLabelsChanged() { face.markRingDirty() }
      function onShowRingsChanged() { face.markRingDirty() }
      function onRingRotationOffsetRadChanged() { face.markRingDirty() }
      function onMinuteRingLabelColorChanged() { face.markRingDirty() }
      function onSecondRingLabelColorChanged() { face.markRingDirty() }
    }

    Connections {
      target: Color
      function onForegroundChanged() { face.markRingDirty() }
      function onBackgroundChanged() { face.markRingDirty() }
      function onMutedChanged() { face.markRingDirty() }
      function onAccentChanged() { face.markRingDirty() }
    }

    Component.onCompleted: face.markRingDirty()

    Column {
      id: hourColumn
      z: 3
      x: face.geo.hourX
      y: face.geo.hourY
      spacing: face.columnSpacing

      Item {
        visible: face.showDate && face.spec.dateInHourColumn && face.spec.dateAboveHour
        width: dateAboveCol.implicitWidth
        height: dateAboveCol.implicitHeight

        DateColumn {
          id: dateAboveCol
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.horizontalCenterOffset: face.dateOffsetX
          y: face.dateOffsetY
          parts: face.now
          use24h: face.use24h
          uiScale: face.dateScale
          clockFont: face.effectiveDateFont
          labelFont: face.effectiveDateLabelFont
          primaryColor: face.colors.datePrimary
          mutedColor: face.colors.dateMuted
        }
      }

      Item {
        visible: face.showHour && !face.spec.digitalReadout
        width: hourText.implicitWidth
        height: hourText.implicitHeight

        Text {
          id: hourText
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.horizontalCenterOffset: face.hourOffsetX
          y: face.hourOffsetY
          text: face.now.hourLabel
          color: face.colors.hour
          font.family: face.effectiveHourFont
          font.pixelSize: face.hourSize
          font.weight: Font.Black
          font.letterSpacing: -3 * face.hourScale
          renderType: Text.NativeRendering
          antialiasing: true
        }
      }

      Item {
        visible: face.showHour && face.spec.digitalReadout
        width: digitalRow.implicitWidth
        height: digitalRow.implicitHeight

        Row {
          id: digitalRow
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.horizontalCenterOffset: face.hourOffsetX
          y: face.hourOffsetY
          spacing: Math.round(6 * face.hourScale)

          Text {
            text: face.now.hourLabel + ":" + face.now.mm
            color: face.colors.hour
            font.family: face.effectiveHourFont
            font.pixelSize: face.hourSize
            font.weight: Font.Black
            font.letterSpacing: -3 * face.hourScale
            renderType: Text.NativeRendering
            antialiasing: true
          }

          Text {
            visible: face.showSeconds
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(face.hourSize * 0.08)
            text: face.now.ss
            color: face.colors.subtime
            font.family: face.labelFont
            font.pixelSize: Math.round(face.hourSize * 0.3)
            font.weight: Font.Medium
            renderType: Text.NativeRendering
            antialiasing: true
          }
        }
      }

      Item {
        visible: face.showDate && face.spec.dateInHourColumn && !face.spec.dateAboveHour
        width: dateBelowCol.implicitWidth
        height: dateBelowCol.implicitHeight

        DateColumn {
          id: dateBelowCol
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.horizontalCenterOffset: face.dateOffsetX
          y: face.dateOffsetY
          parts: face.now
          use24h: face.use24h
          uiScale: face.dateScale
          clockFont: face.effectiveDateFont
          labelFont: face.effectiveDateLabelFont
          primaryColor: face.colors.datePrimary
          mutedColor: face.colors.dateMuted
        }
      }
    }
  }

  TimeCapsule {
    id: minutePill
    z: 10
    visible: face.spec.showCapsules && face.showMinuteCapsule
    uiScale: face.minuteCapsuleScale
    textScale: face.minuteCapsuleScale
    width: face.spec.singleCapsule ? Math.round(62 * face.minuteCapsuleScale) : face.minutePillWidth
    fontFamily: face.effectiveMinuteCapsuleFont
    fontSize: 15
    textColor: face.colors.minuteCapsuleText
    fillColor: face.themedInk(face.colors.capsuleFill, 0.96)
    borderColor: face.themedInk(face.colors.capsuleBorder, 0.55)
    text: face.minuteCapsuleText

    readonly property point focusPos: face.capsulePoint(
      (face.spec.singleCapsule
        ? (face.showSeconds ? face.secondRadius : face.minuteRadius)
        : face.minuteRadius) + face.minuteCapsuleRadiusOffset,
      face.minuteCapsuleRenderAngle + face.minuteCapsuleAngleOffsetRad
    )
    x: focusPos.x - width / 2
    y: focusPos.y - height / 2
  }

  TimeCapsule {
    id: secondPill
    visible: face.showSeconds && face.spec.showCapsules && !face.spec.singleCapsule && face.showSecondCapsule
    z: 11
    uiScale: face.secondCapsuleScale
    textScale: face.secondCapsuleScale
    width: face.secondPillWidth
    fontFamily: face.effectiveSecondCapsuleFont
    fontSize: 14
    fontWeight: Font.Medium
    textColor: face.colors.secondCapsuleText
    fillColor: face.themedInk(face.colors.capsuleFill, 0.96)
    borderColor: face.themedInk(face.colors.capsuleBorder, 0.45)
    text: face.secondCapsuleText

    readonly property point focusPos: face.capsulePoint(
      face.secondRadius + face.secondCapsuleRadiusOffset,
      face.secondCapsuleRenderAngle + face.secondCapsuleAngleOffsetRad
    )
    x: focusPos.x - width / 2
    y: focusPos.y - height / 2
  }

  DateColumn {
    id: centerDateBlock
    visible: face.showDate && face.spec.dateBelowDial
    z: 3
    anchors.horizontalCenter: dialBlock.horizontalCenter
    anchors.horizontalCenterOffset: face.dateOffsetX
    y: face.geo.dateY + face.dateOffsetY
    parts: face.now
    use24h: face.use24h
    uiScale: face.dateScale
    clockFont: face.effectiveDateFont
    labelFont: face.effectiveDateLabelFont
    dateFontSize: 12
    dayFontSize: 20
    primaryColor: face.colors.datePrimary
    mutedColor: face.colors.dateMuted
  }
}
