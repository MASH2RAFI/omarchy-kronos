import Quickshell
import Quickshell.Io
import "PluginConfig.js" as Config

// Works around a host limitation: the scoped shell object Service.qml/
// SettingsPanel.qml receive caches `barConfig` as a one-time snapshot (see
// PluginConfig.js findBarEntry for the full explanation), so it never
// reflects settings-panel edits made after the plugin was loaded — only a
// full shell restart refreshes it. This watches shell.json directly instead,
// so `entry` always reflects what's actually on disk right now.
FileView {
  id: root

  property string pluginId: ""
  property var entry: null

  path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
  watchChanges: true
  printErrors: false

  function refresh() {
    var raw = root.text() || ""
    if (!raw.trim()) return
    try {
      var parsed = JSON.parse(raw)
      root.entry = Config.findEntryInBarConfig(parsed.bar, root.pluginId) || null
    } catch (e) {
      // Transient parse failure (e.g. caught mid-write) — keep the last good entry.
    }
  }

  onLoaded: refresh()
  onFileChanged: reload()
  onLoadFailed: function(error) {}
}
