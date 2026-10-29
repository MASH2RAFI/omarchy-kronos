import QtQuick
import qs.Commons

// Full ring dial — 60 ticks, numeric label at every tick (00–59).
//
// Picks the renderer: ShaderRingCanvas.qml (rings rasterised once, rotated on
// the GPU) by default, or LegacyRingCanvas.qml (whole canvas repainted every
// tick) when `renderer` is "canvas" or the shader fails to load. Both share the
// same properties, so callers only see this item.
Item {
  id: root

  property string renderer: "shader"

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

  property bool shaderFailed: false
  readonly property bool useShader: root.renderer !== "canvas" && !root.shaderFailed

  readonly property var forwardedProperties: [
    "cx", "cy", "minuteRadius", "secondRadius", "minuteProgress", "secondProgress",
    "focusAngle", "fullRing", "showSeconds", "ringStrength", "ringColor",
    "secondRingColor", "minuteLabelColor", "secondLabelColor", "showLabels",
    "labelScale", "chromeScale", "labelFont", "arcFrom", "arcTo", "showGuideRing",
    "arcEmphasis", "arcEdgeFade"
  ]

  // Geometry, colour or font changed: re-raster.
  function repaint() {
    if (loader.item) loader.item.repaint()
  }

  // Called on every clock tick. The shader renderer rotates through bindings;
  // only the canvas renderer has to repaint.
  function tick() {
    if (loader.item && !root.useShader) loader.item.repaint()
  }

  Loader {
    id: loader
    anchors.fill: parent
    source: root.useShader ? "ShaderRingCanvas.qml" : "LegacyRingCanvas.qml"

    onStatusChanged: {
      if (loader.status === Loader.Error && root.useShader) {
        console.warn("Kronos: shader ring renderer failed to load, using canvas renderer")
        root.shaderFailed = true
      }
    }

    onLoaded: {
      for (var i = 0; i < root.forwardedProperties.length; i++) {
        var name = root.forwardedProperties[i]
        loader.item[name] = Qt.binding((function(key) {
          return function() { return root[key] }
        })(name))
      }
      if (root.useShader)
        loader.item.failed.connect(function() { root.shaderFailed = true })
      loader.item.repaint()
    }
  }
}
