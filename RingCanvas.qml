import QtQuick
import qs.Commons
import "ClockModel.js" as Clock
import "ClockTheme.js" as Theme

// Full ring dial — 60 ticks, numeric label at every tick (00–59).
Canvas {
  id: canvas

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
  property color secondRingColor: canvas.ringColor
  property color minuteLabelColor: canvas.ringColor
  property color secondLabelColor: canvas.secondRingColor
  property bool showLabels: true
  property real labelScale: 1
  property real chromeScale: 1
  property string labelFont: Style.font.family
  property real arcFrom: NaN
  property real arcTo: NaN
  property bool showGuideRing: false
  property bool arcEmphasis: false
  property real arcEdgeFade: 0.05

  renderStrategy: Canvas.Cooperative
  renderTarget: Canvas.FramebufferObject

  readonly property bool arcClip: Clock.arcBoundsActive(canvas.arcFrom, canvas.arcTo)
  readonly property real arcFromArg: canvas.arcClip ? canvas.arcFrom : null
  readonly property real arcToArg: canvas.arcClip ? canvas.arcTo : null

  function labelVisible(angle) {
    return Clock.isRingLabelVisible(angle, canvas.fullRing, canvas.arcFromArg, canvas.arcToArg)
  }

  function drawDotRing(ctx, radius, progress, dotColor, labelColor) {
    var s = canvas.labelScale
    var fontPx = Math.max(7, Math.round(8 * s))
    var dotR = Math.max(1.1, 1.3 * s)
    var strength = canvas.ringStrength
    var rotation = Clock.ringRotationRad(progress, canvas.focusAngle)
    var angles = Clock.ringAngles()
    var fontFamilies = canvas.labelFont.split(",").map(function(f) { return "\"" + f.trim() + "\"" }).join(", ")
    var font = "500 " + fontPx + "px " + fontFamilies
    var labelRBase = radius + Math.round(10 * s)
    var clipArc = canvas.arcClip

    ctx.save()
    ctx.translate(canvas.cx, canvas.cy)
    ctx.rotate(rotation)
    ctx.translate(-canvas.cx, -canvas.cy)
    ctx.font = font
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"

    for (var i = 0; i < 60; i++) {
      var angle = angles[i]
      var worldAngle = Clock.normalizeAngle0(angle + rotation)
      if (clipArc && !Clock.dotOnArc(worldAngle, canvas.arcFrom, canvas.arcTo))
        continue
      var onFace = canvas.fullRing || clipArc || canvas.labelVisible(worldAngle)
      var fade = clipArc ? 1 : Clock.ringDotFade(i, progress, onFace)
      var px = canvas.cx + Math.cos(angle) * radius
      var py = canvas.cy + Math.sin(angle) * radius
      var alpha = Clock.ringDotAlpha(true, fade, onFace, strength)
      if (clipArc)
        alpha *= Clock.ringEdgeMeetFade(worldAngle, canvas.arcFrom, canvas.arcTo, canvas.arcEdgeFade)
      if (clipArc && canvas.arcEmphasis)
        alpha = Math.min(1, alpha * 1.15)

      ctx.beginPath()
      ctx.fillStyle = Theme.ink(dotColor, alpha)
      ctx.arc(px, py, dotR, 0, Math.PI * 2)
      ctx.fill()

      if (canvas.showLabels) {
        var labelR = labelRBase
        ctx.save()
        ctx.translate(canvas.cx + Math.cos(angle) * labelR, canvas.cy + Math.sin(angle) * labelR)
        ctx.rotate(angle + Math.PI / 2)
        var labelAlpha = onFace ? (0.44 + fade * 0.52) : (0.24 + fade * 0.28)
        if (clipArc)
          labelAlpha *= Clock.ringEdgeMeetFade(worldAngle, canvas.arcFrom, canvas.arcTo, canvas.arcEdgeFade)
        if (clipArc && canvas.arcEmphasis)
          labelAlpha = Math.min(1, labelAlpha * 1.12)
        ctx.fillStyle = Theme.ink(labelColor, Math.min(1, labelAlpha * strength))
        ctx.fillText(Clock.pad2(i), 0, 0)
        ctx.restore()
      }
    }

    ctx.restore()
  }

  function repaint() { requestPaint() }

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    ctx.clearRect(0, 0, width, height)

    var outerR = canvas.showSeconds ? canvas.secondRadius : canvas.minuteRadius
    var guideR = outerR + Math.round(16 * canvas.chromeScale) * 0.42
    var lw = Math.max(1, canvas.chromeScale * 0.8)
    var guideAlpha = 0.14 * canvas.ringStrength * (canvas.arcEmphasis ? 2 : 1)

    if (canvas.showGuideRing && canvas.fullRing) {
      ctx.beginPath()
      ctx.strokeStyle = Theme.ink(canvas.ringColor, 0.07 * canvas.ringStrength)
      ctx.lineWidth = lw
      ctx.arc(canvas.cx, canvas.cy, guideR, 0, Math.PI * 2)
      ctx.stroke()
    }

    if (canvas.arcClip) {
      var guideFrom = Clock.normalizeAngle0(canvas.arcFrom)
      var guideTo = Clock.normalizeAngle0(canvas.arcTo)
      var arcLw = lw * (canvas.arcEmphasis ? 1.55 : 1)
      ctx.beginPath()
      ctx.strokeStyle = Theme.ink(canvas.ringColor, guideAlpha)
      ctx.lineWidth = arcLw
      ctx.arc(canvas.cx, canvas.cy, guideR, guideFrom, guideTo)
      ctx.stroke()
      if (canvas.arcEmphasis) {
        var innerGuideR = canvas.minuteRadius + Math.round(16 * canvas.chromeScale) * 0.42
        ctx.beginPath()
        ctx.strokeStyle = Theme.ink(canvas.ringColor, guideAlpha * 0.75)
        ctx.lineWidth = Math.max(1, arcLw * 0.9)
        ctx.arc(canvas.cx, canvas.cy, innerGuideR, guideFrom, guideTo)
        ctx.stroke()
      }
    }

    canvas.drawDotRing(ctx, canvas.minuteRadius, canvas.minuteProgress, canvas.ringColor, canvas.minuteLabelColor)
    if (canvas.showSeconds)
      canvas.drawDotRing(ctx, canvas.secondRadius, canvas.secondProgress, canvas.secondRingColor, canvas.secondLabelColor)
  }
}
