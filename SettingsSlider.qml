import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Column {
  id: root

  property var bar
  property string label: ""
  property string helpText: ""
  property real minimum: 0
  property real maximum: 1
  property real step: 0.01
  property real value: 0
  property string valueText: ""
  property bool livePreview: true

  signal moved(real value)
  signal released(real value)

  width: parent ? parent.width : implicitWidth
  spacing: Style.spacing.md

  Text {
    width: parent.width
    visible: root.label !== ""
    text: root.label
    color: Qt.darker(Commons.Color.foreground, 1.4)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.bold: true
  }

  Row {
    width: parent.width
    spacing: Style.spacing.md

    PanelSlider {
      bar: root.bar
      width: parent.width - valueLabel.width - parent.spacing
      minimum: root.minimum
      maximum: root.maximum
      step: root.step
      value: root.value
      onMoved: function(v) {
        if (root.livePreview) root.moved(v)
      }
      onReleased: function(v) {
        root.released(v)
      }
    }

    Text {
      id: valueLabel
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(44)
      horizontalAlignment: Text.AlignRight
      text: root.valueText
      color: Commons.Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
  }

  Text {
    width: parent.width
    visible: root.helpText !== ""
    wrapMode: Text.WordWrap
    text: root.helpText
    color: Qt.darker(Commons.Color.foreground, 1.45)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
