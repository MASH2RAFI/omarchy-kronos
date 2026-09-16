import QtQuick
import qs.Commons
import qs.Ui
import "ClockModel.js" as Clock
import "PluginConfig.js" as Config

BarWidget {
  id: root
  moduleName: "mash2rafi.kronos"

  readonly property var shell: root.bar ? root.bar.shell : null
  readonly property var pluginEntry: Config.entryOrDefault(root.shell, root.moduleName)
  readonly property var cfg: Clock.readSettings(root.pluginEntry)
  readonly property bool clockEnabled: root.cfg.clockEnabled !== false

  function toggleClock() {
    if (!root.shell || typeof root.shell.updateEntryInline !== "function") return
    root.shell.updateEntryInline(
      root.moduleName,
      Clock.settingsToEntry(
        root.moduleName,
        Clock.mergeSettings(root.moduleName, root.cfg, { clockEnabled: !root.clockEnabled })
      )
    )
  }

  function openSettings() {
    if (root.shell && typeof root.shell.summon === "function")
      root.shell.summon(root.moduleName, "{}")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰥔"
    slotSize: Style.bar.statusSlot
    active: root.clockEnabled
    useActiveColor: true
    tooltipText: root.clockEnabled
      ? "Kronos on — click to hide, right-click for settings"
      : "Kronos off — click to show, right-click for settings"
    onPressed: function(button) {
      if (button === Qt.RightButton) root.openSettings()
      else root.toggleClock()
    }
  }
}
