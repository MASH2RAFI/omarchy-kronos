import QtQuick
import qs.Commons
import "ClockModel.js" as Clock
import "ClockTheme.js" as Theme

// Shader ring renderer (selected by RingCanvas.qml; LegacyRingCanvas.qml is the
// per-tick Canvas fallback). Full ring dial — 60 ticks, labels 00–59.
//
// Cached-texture renderer. Each ring's 60 dots + labels are rasterised ONCE
// into its own Canvas (ring-local frame, full opacity) and the scene graph
// only rotates that texture. The per-dot alpha — a function of the dot's
// WORLD angle (focus fade, arc clipping and arc-end fade) — is baked into a
// 1-D world-angle lookup texture. A small fragment shader (shaders/ringmask.frag)
// rotates each ring texture and applies that lookup in a single draw call:
// no offscreen pass, no per-frame raster or texture upload — per tick the CPU
// only updates two rotation uniforms. Same public API as the per-frame Canvas version, except
// repaint() is now only needed when geometry/colours/fonts change (rotation
// follows minuteProgress/secondProgress bindings by itself).
Item {
  id: root

  // Emitted once if either ring shader fails to load or compile, so
  // RingCanvas.qml can swap in the Canvas renderer.
  signal failed(string reason)
  property bool failureReported: false

  property real cx: 0
  property real cy: 0
  property real minuteRadius: 96
  property real secondRadius: 120
  property real minuteProgress: 0
  property real secondProgress: 0
  property real focusAngle: 0
  property bool fullRing: false
  property bool showSeconds: true
  property real ringStrength: 1
  property color ringColor: Color.foreground
  property color secondRingColor: root.ringColor
  property color minuteLabelColor: root.ringColor
  property color secondLabelColor: root.secondRingColor
  property bool showLabels: true
  property real labelScale: 1
  property real chromeScale: 1
  property string labelFont: Style.font.family
  property real arcFrom: NaN
  property real arcTo: NaN
  property bool showGuideRing: false
  property bool arcEmphasis: false
  property real arcEdgeFade: 0.05

  readonly property bool arcClip: Clock.arcBoundsActive(root.arcFrom, root.arcTo)
  // Ring textures are sampled rotated, so they are captured at device pixels
  // (not logical size) to stay sharp on scaled outputs (1.5x, 2x).
  readonly property real dpr: Math.max(1, Screen.devicePixelRatio)
  readonly property url shaderUrl: Qt.resolvedUrl("shaders/ringmask.frag.qsb")

  function checkShader(effect) {
    if (effect.status !== ShaderEffect.Error || root.failureReported) return
    root.failureReported = true
    console.warn("Kronos: ring shader unavailable, using canvas renderer: " + effect.log)
    root.failed(effect.log)
  }

  readonly property real fontPx: Math.max(7, Math.round(8 * root.labelScale))
  readonly property real dotR: Math.max(1.1, 1.3 * root.labelScale)
  readonly property real labelOffset: Math.round(10 * root.labelScale)
  // Ring texture half-size: label centre radius + half a rotated label + AA pad.
  readonly property real ringPad: root.labelOffset + root.fontPx + 3

  // Label alpha relative to dot alpha (the mask carries the dot alpha). The
  // canvas formulas differ by a near-constant factor; use its value at full fade
  // (labels end up at most ~3.6% brighter than the canvas at the dimmest fade).
  readonly property real labelRelAlpha: {
    var dotA = root.arcClip ? Math.min(1, 1 * (root.arcEmphasis ? 1.15 : 1)) : 1
    var labA = root.arcClip ? Math.min(1, 0.96 * (root.arcEmphasis ? 1.12 : 1)) : 0.96
    return Math.min(1, labA / dotA)
  }

  function repaint() {
    guide.requestPaint()
    minuteTex.requestPaint()
    secondTex.requestPaint()
    mask.requestPaint()
  }

  onWidthChanged: root.repaint()
  onHeightChanged: root.repaint()

  // World-space alpha of a dot at world angle `a` (mirrors drawDotRing()).
  function worldAlpha(a) {
    var strength = root.ringStrength
    if (root.arcClip) {
      if (!Clock.dotOnArc(a, root.arcFrom, root.arcTo)) return 0
      var alpha = Clock.ringDotAlpha(true, 1, true, strength)
      alpha *= Clock.ringEdgeMeetFade(a, root.arcFrom, root.arcTo, root.arcEdgeFade)
      if (root.arcEmphasis) alpha = Math.min(1, alpha * 1.15)
      return alpha
    }
    // Index-space fade: dot i sits at world angle focus + (i - progress) * step,
    // so fade(i, progress) == fade(x, 0) with x the world offset in ticks.
    var x = Clock.normalizeAngle0(a - root.focusAngle) * 60 / (Math.PI * 2)
    var fade = Clock.ringDotFade(x, 0, true)
    return Clock.ringDotAlpha(true, fade, true, strength)
  }

  // Ring-local raster at full opacity; alpha comes from the world-space mask.
  function paintRing(ctx, c, radius, dotColor, labelColor) {
    ctx.reset()
    ctx.clearRect(0, 0, c * 2, c * 2)
    var angles = Clock.ringAngles()
    ctx.fillStyle = Theme.ink(dotColor, 1)
    for (var i = 0; i < 60; i++) {
      ctx.beginPath()
      ctx.arc(c + Math.cos(angles[i]) * radius, c + Math.sin(angles[i]) * radius, root.dotR, 0, Math.PI * 2)
      ctx.fill()
    }
    if (!root.showLabels) return
    var fontFamilies = root.labelFont.split(",").map(function(f) { return "\"" + f.trim() + "\"" }).join(", ")
    ctx.font = "500 " + root.fontPx + "px " + fontFamilies
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    ctx.fillStyle = Theme.ink(labelColor, root.labelRelAlpha)
    var labelR = radius + root.labelOffset
    for (var j = 0; j < 60; j++) {
      ctx.save()
      ctx.translate(c + Math.cos(angles[j]) * labelR, c + Math.sin(angles[j]) * labelR)
      ctx.rotate(angles[j] + Math.PI / 2)
      ctx.fillText(Clock.pad2(j), 0, 0)
      ctx.restore()
    }
  }

  Canvas {
    id: guide
    anchors.fill: parent
    renderStrategy: Canvas.Cooperative
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      ctx.clearRect(0, 0, width, height)
      var outerR = root.showSeconds ? root.secondRadius : root.minuteRadius
      var guideR = outerR + Math.round(16 * root.chromeScale) * 0.42
      var lw = Math.max(1, root.chromeScale * 0.8)
      var guideAlpha = 0.14 * root.ringStrength * (root.arcEmphasis ? 2 : 1)
      if (root.showGuideRing && root.fullRing) {
        ctx.beginPath()
        ctx.strokeStyle = Theme.ink(root.ringColor, 0.07 * root.ringStrength)
        ctx.lineWidth = lw
        ctx.arc(root.cx, root.cy, guideR, 0, Math.PI * 2)
        ctx.stroke()
      }
      if (root.arcClip) {
        var guideFrom = Clock.normalizeAngle0(root.arcFrom)
        var guideTo = Clock.normalizeAngle0(root.arcTo)
        var arcLw = lw * (root.arcEmphasis ? 1.55 : 1)
        ctx.beginPath()
        ctx.strokeStyle = Theme.ink(root.ringColor, guideAlpha)
        ctx.lineWidth = arcLw
        ctx.arc(root.cx, root.cy, guideR, guideFrom, guideTo)
        ctx.stroke()
        if (root.arcEmphasis) {
          var innerGuideR = root.minuteRadius + Math.round(16 * root.chromeScale) * 0.42
          ctx.beginPath()
          ctx.strokeStyle = Theme.ink(root.ringColor, guideAlpha * 0.75)
          ctx.lineWidth = Math.max(1, arcLw * 0.9)
          ctx.arc(root.cx, root.cy, innerGuideR, guideFrom, guideTo)
          ctx.stroke()
        }
      }
    }
  }

  // Ring rasters (ring-local, unrotated). Hidden: they are only shader sources.
  Canvas {
    id: minuteTex
    readonly property real half: Math.ceil(root.minuteRadius + root.ringPad)
    width: half * 2
    height: half * 2
    renderStrategy: Canvas.Cooperative
    onWidthChanged: requestPaint()
    onPaint: root.paintRing(getContext("2d"), half, root.minuteRadius, root.ringColor, root.minuteLabelColor)
  }

  Canvas {
    id: secondTex
    readonly property real half: Math.ceil(root.secondRadius + root.ringPad)
    width: half * 2
    height: half * 2
    renderStrategy: Canvas.Cooperative
    onWidthChanged: requestPaint()
    onPaint: root.paintRing(getContext("2d"), half, root.secondRadius, root.secondRingColor, root.secondLabelColor)
  }

  // Static texture snapshots of the rasters. They only re-render when the
  // canvas repaints (geometry/colour/font change), never per frame.
  ShaderEffectSource {
    id: minuteSrc
    visible: false
    sourceItem: minuteTex
    textureSize: Qt.size(Math.ceil(minuteTex.width * root.dpr), Math.ceil(minuteTex.height * root.dpr))
    hideSource: true
    smooth: true
  }

  ShaderEffectSource {
    id: secondSrc
    visible: false
    sourceItem: secondTex
    textureSize: Qt.size(Math.ceil(secondTex.width * root.dpr), Math.ceil(secondTex.height * root.dpr))
    hideSource: true
    smooth: true
  }

  ShaderEffectSource {
    id: lutSrc
    visible: false
    sourceItem: mask
    hideSource: true
    smooth: true
  }

  // World-angle alpha lookup: texel k covers angle k * 360° / width.
  Canvas {
    id: mask
    width: 1440
    height: 1
    renderStrategy: Canvas.Cooperative
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var img = ctx.createImageData(1440, 1)
      var d = img.data
      for (var k = 0; k < 1440; k++) {
        var o = k * 4
        d[o] = 255; d[o + 1] = 255; d[o + 2] = 255
        d[o + 3] = Math.round(255 * root.worldAlpha((k + 0.5) * Math.PI * 2 / 1440))
      }
      ctx.drawImage(img, 0, 0)
    }
  }

  ShaderEffect {
    id: minuteFx
    anchors.fill: parent
    readonly property point center: Qt.point(root.cx, root.cy)
    readonly property size itemSize: Qt.size(width, height)
    readonly property real texHalf: minuteTex.half
    readonly property real ringRotation: Clock.ringRotationRad(root.minuteProgress, root.focusAngle)
    readonly property var ringTex: minuteSrc
    readonly property var lut: lutSrc
    fragmentShader: root.shaderUrl
    onStatusChanged: root.checkShader(minuteFx)
    Component.onCompleted: root.checkShader(minuteFx)
  }

  ShaderEffect {
    id: secondFx
    anchors.fill: parent
    visible: root.showSeconds
    readonly property point center: Qt.point(root.cx, root.cy)
    readonly property size itemSize: Qt.size(width, height)
    readonly property real texHalf: secondTex.half
    readonly property real ringRotation: Clock.ringRotationRad(root.secondProgress, root.focusAngle)
    readonly property var ringTex: secondSrc
    readonly property var lut: lutSrc
    fragmentShader: root.shaderUrl
    onStatusChanged: root.checkShader(secondFx)
    Component.onCompleted: root.checkShader(secondFx)
  }
}
