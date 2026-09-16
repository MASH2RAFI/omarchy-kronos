import QtQuick
import qs.Commons
import qs.Ui

// Hex color override field: swatch + "#RRGGBB" text input + "Auto" reset.
// Empty value means "use the theme-derived color" — the swatch shows a
// checkerboard-free transparent hint via a dashed border instead of a fill.
Column {
  id: root

  property string label: ""
  property string helpText: ""
  property string value: ""

  signal changed(string value)

  readonly property bool valueValid: /^#[0-9A-Fa-f]{6}$/.test(root.value)

  width: parent ? parent.width : implicitWidth
  spacing: Style.spacing.md

  Text {
    width: parent.width
    visible: root.label !== ""
    text: root.label
    color: Qt.darker(Color.foreground, 1.4)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.bold: true
  }

  Row {
    width: parent.width
    spacing: Style.spacing.md

    Rectangle {
      id: swatch
      width: Style.spacing.controlHeight
      height: Style.spacing.controlHeight
      radius: Style.cornerRadius
      anchors.verticalCenter: parent.verticalCenter
      color: root.valueValid ? root.value : "transparent"
      border.color: Qt.darker(Color.foreground, 1.6)
      border.width: root.valueValid ? 1 : Math.max(1, Style.space(1))
    }

    TextField {
      id: hexField
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - swatch.width - autoButton.width - parent.spacing * 2
      text: root.value
      placeholderText: "Auto"
      validator: RegularExpressionValidator { regularExpression: /#?[0-9A-Fa-f]{0,6}/ }
      onEditingFinished: {
        var v = text.trim()
        if (v !== "" && v[0] !== "#") v = "#" + v
        if (v !== "" && !/^#[0-9A-Fa-f]{6}$/.test(v)) v = root.value
        if (v !== root.value) {
          root.value = v
          root.changed(v)
        } else {
          text = root.value
        }
      }
    }

    Button {
      id: autoButton
      anchors.verticalCenter: parent.verticalCenter
      text: "Auto"
      focusable: true
      enabled: root.value !== ""
      onClicked: {
        root.value = ""
        hexField.text = ""
        root.changed("")
      }
    }
  }

  Text {
    width: parent.width
    visible: root.helpText !== ""
    wrapMode: Text.WordWrap
    text: root.helpText
    color: Qt.darker(Color.foreground, 1.45)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
