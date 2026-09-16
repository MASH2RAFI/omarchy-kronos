.pragma library

function findEntry(shell, pluginId) {
  var config = shell && shell.shellConfig ? shell.shellConfig : null
  if (!config || !Array.isArray(config.plugins)) return null
  for (var i = 0; i < config.plugins.length; i++) {
    var entry = config.plugins[i]
    if (entry && String(entry.id || "") === pluginId) return entry
  }
  return null
}

function findEntryInBarConfig(barConfig, pluginId) {
  if (!barConfig || !barConfig.layout) return null
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var arr = barConfig.layout[sections[s]] || []
    for (var i = 0; i < arr.length; i++) {
      var entry = arr[i]
      if (entry && String(entry.id || "") === pluginId) return entry
    }
  }
  return null
}

function findBarEntry(shell, pluginId) {
  // Third-party plugins receive a scoped PluginShellApi (services/PluginShellApi.qml),
  // which exposes `barConfig` (the bar section itself) but has no `shellConfig` —
  // that property only exists on the host's unscoped, first-party shell object.
  //
  // Even `barConfig` itself is a one-time snapshot: shell.qml's
  // createScopedPluginShell() sets it via `barConfig: shell.publicBarConfig()`,
  // a plain value (not Qt.binding), taken once when the scoped shell object is
  // created and never reassigned again — that object is cached and reused for
  // the plugin's whole lifetime (services/PluginShellApi.qml, shell.qml
  // pluginShellCapabilityProfile()). So this path only ever reflects whatever
  // shell.json looked like at plugin load, not live edits made afterward.
  // ShellConfigWatcher.qml exists specifically to route around that by
  // reading shell.json directly; prefer its `entry` over this function
  // wherever a live value is needed (Service.qml, SettingsPanel.qml).
  return findEntryInBarConfig(shell && shell.barConfig ? shell.barConfig : null, pluginId)
}

function entryOrDefault(shell, pluginId) {
  var pluginEntry = findEntry(shell, pluginId)
  var barEntry = findBarEntry(shell, pluginId)
  if (!pluginEntry && !barEntry) return { id: pluginId }
  if (!barEntry) return pluginEntry || { id: pluginId }
  if (!pluginEntry) return barEntry
  var merged = { id: pluginId }
  for (var key in pluginEntry) if (key !== "id") merged[key] = pluginEntry[key]
  for (var bkey in barEntry) if (bkey !== "id") merged[bkey] = barEntry[bkey]
  return merged
}

function defaultSettings() {
  return {
    scale: 1,
    hourScale: 0.75,
    dateScale: 1,
    subtimeScale: 1,
    ringLabelScale: 1,
    minuteCapsuleScale: 1.7,
    secondCapsuleScale: 1,
    hourColor: "",
    dateColor: "",
    minuteCapsuleColor: "",
    secondCapsuleColor: "",
    minuteRingColor: "",
    secondRingColor: "",
    ringLabelColor: "",
    hourFont: "",
    dateFont: "",
    minuteCapsuleFont: "",
    secondCapsuleFont: "",
    showHour: true,
    showMinuteCapsule: true,
    showSecondCapsule: true,
    showRingLabels: true,
    showRings: true,
    hourOffsetX: 0,
    hourOffsetY: 0,
    dateOffsetX: 0,
    dateOffsetY: 0,
    minuteCapsuleAngleOffset: 12,
    secondCapsuleAngleOffset: -18,
    minuteCapsuleRadiusOffset: 1,
    secondCapsuleRadiusOffset: 0,
    ringRotationOffset: 0,
    position: "top-right",
    centerLayout: "orbit",
    use24h: false,
    showSeconds: true,
    showDate: true,
    clockEnabled: true,
    accentMode: "theme",
    margin: 12,
    barPadding: 0,
    ringDiameter: 0.29,
    ringGap: 57,
    ringArcDegrees: 0,
    ringTransparency: 1,
    minuteRingOpacity: 1,
    secondRingOpacity: 1,
    screenMode: "all",
    selectedMonitors: [],
    perMonitorScale: false,
    scaleReferenceHeight: 1080,
    savedLayouts: [],
    clockFont: "Liberation Sans",
    labelFont: "JetBrainsMono Nerd Font,JetBrainsMono NF"
  }
}
