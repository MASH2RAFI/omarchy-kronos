.pragma library

var MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

function pad2(n) {
  return (n < 10 ? "0" : "") + n
}

function partsAt(ms, use24h) {
  var d = new Date(ms)
  var h = d.getHours()
  var minutes = d.getMinutes()
  var seconds = d.getSeconds()
  var millis = d.getMilliseconds()
  var h12 = (h % 12) === 0 ? 12 : (h % 12)
  var secondFloat = seconds + millis / 1000
  var minuteFloat = minutes + secondFloat / 60

  return {
    hourLabel: use24h ? String(h) : String(h12),
    mm: pad2(minutes),
    ss: pad2(seconds),
    ampm: h < 12 ? "AM" : "PM",
    dateShort: d.getDate() + " " + MONTHS[d.getMonth()] + " " + d.getFullYear(),
    dayName: Qt.formatDate(d, "dddd").toUpperCase(),
    minuteFloat: minuteFloat,
    secondFloat: secondFloat
  }
}

function clampNumber(value, fallback, min, max, roundTo) {
  var n = Number(value)
  if (!isFinite(n)) n = fallback
  n = Math.max(min, Math.min(max, n))
  if (roundTo === 100) return Math.round(n * 100) / 100
  if (roundTo !== false) return Math.round(n)
  return n
}

function clampScale(value) {
  return clampNumber(value, 1, 0.5, 2.5, false)
}

function clampTextScale(value) {
  return clampNumber(value, 1, 0.5, 2.5, false)
}

function roundScale(value) {
  return Math.round(Number(value) * 100) / 100
}

function readTextScale(entry, key, legacyKeys, fallback) {
  entry = entry || {}
  if (entry[key] !== undefined && entry[key] !== null)
    return clampTextScale(entry[key])
  if (legacyKeys !== undefined && legacyKeys !== null) {
    if (!Array.isArray(legacyKeys)) legacyKeys = [legacyKeys]
    for (var i = 0; i < legacyKeys.length; i++) {
      var legacy = legacyKeys[i]
      if (entry[legacy] !== undefined && entry[legacy] !== null)
        return clampTextScale(entry[legacy])
    }
  }
  return fallback !== undefined ? fallback : 1
}

var HEX_COLOR_RE = /^#[0-9A-Fa-f]{6}$/

function readColorOverride(entry, key) {
  entry = entry || {}
  var value = entry[key]
  if (value === undefined || value === null) return ""
  var s = String(value)
  return HEX_COLOR_RE.test(s) ? s : ""
}

function readFontOverride(entry, key) {
  entry = entry || {}
  var value = entry[key]
  return value === undefined || value === null ? "" : String(value)
}

function clampOffset(value, min, max, fallback) {
  return clampNumber(value, fallback !== undefined ? fallback : 0, min, max, true)
}

function hourSizeFromScale(hourScale, sizeFactor) {
  var base = Math.round(150 * clampTextScale(hourScale))
  sizeFactor = Number(sizeFactor) || 1
  if (sizeFactor !== 1) base = Math.round(base * sizeFactor)
  return base
}

function clampMargin(value) {
  return clampNumber(value, 48, 0, 240, true)
}

function clampRingDiameter(value) {
  return clampNumber(value, 0.40, 0.25, 0.55, 100)
}

function clampRingGap(value) {
  return clampNumber(value, 48, 24, 100, true)
}

function clampRingOpacity(value) {
  return clampNumber(value, 1, 0, 1, 100)
}

function defaultArcDegreesForPosition(position) {
  var zone = positionZone(position)
  if (zone === "center") return 360
  if (zone === "middle") return 180
  return 120
}

function clampRingArcDegrees(value, position) {
  var fallback = defaultArcDegreesForPosition(position)
  var n = Number(value)
  if (!isFinite(n) || n <= 0) n = fallback
  return clampNumber(n, fallback, 30, 360, true)
}

function readRingTransparency(entry) {
  if (!entry) return 1
  if (entry.ringTransparency !== undefined && entry.ringTransparency !== null)
    return clampRingOpacity(entry.ringTransparency)
  var minute = clampRingOpacity(entry.minuteRingOpacity !== undefined ? entry.minuteRingOpacity : 1)
  var second = clampRingOpacity(entry.secondRingOpacity !== undefined ? entry.secondRingOpacity : 1)
  return clampRingOpacity((minute + second) / 2)
}

// Fields that describe *where/whether* the clock runs rather than how it
// looks. Saved layouts are appearance presets, so applying one must never
// touch these, and a snapshot never stores them (or itself, recursively).
var LAYOUT_PRESET_EXCLUDED_KEYS = [
  "screenMode", "selectedMonitors", "perMonitorScale", "scaleReferenceHeight",
  "clockEnabled", "savedLayouts"
]

function normalizeSavedLayouts(value) {
  if (!Array.isArray(value)) return []
  var out = []
  for (var i = 0; i < value.length; i++) {
    var entry = value[i]
    if (!entry || typeof entry !== "object") continue
    var id = String(entry.id || "").trim()
    var name = String(entry.name || "").trim()
    if (id === "" || name === "") continue
    var settings = (entry.settings && typeof entry.settings === "object") ? entry.settings : {}
    out.push({ id: id, name: name, settings: snapshotForLayout(settings) })
  }
  return out
}

function snapshotForLayout(settings) {
  settings = settings || {}
  var out = {}
  for (var key in settings) {
    if (LAYOUT_PRESET_EXCLUDED_KEYS.indexOf(key) >= 0) continue
    out[key] = settings[key]
  }
  return out
}

function applyLayoutSnapshot(currentSettings, snapshot) {
  var merged = {}
  currentSettings = currentSettings || {}
  snapshot = snapshot || {}
  for (var key in currentSettings) merged[key] = currentSettings[key]
  for (var skey in snapshot) {
    if (LAYOUT_PRESET_EXCLUDED_KEYS.indexOf(skey) >= 0) continue
    merged[skey] = snapshot[skey]
  }
  return merged
}

function generateLayoutId() {
  return "layout-" + Date.now().toString(36) + "-" + Math.floor(Math.random() * 46656).toString(36)
}

function saveLayoutPreset(savedLayouts, name, settings) {
  var list = normalizeSavedLayouts(savedLayouts).slice()
  var trimmed = String(name || "").trim()
  if (trimmed === "") return list
  list.push({ id: generateLayoutId(), name: trimmed, settings: snapshotForLayout(settings) })
  return list
}

function updateLayoutPreset(savedLayouts, id, updates) {
  var list = normalizeSavedLayouts(savedLayouts).slice()
  for (var i = 0; i < list.length; i++) {
    if (list[i].id !== id) continue
    var next = { id: id, name: list[i].name, settings: list[i].settings }
    if (updates && updates.name !== undefined) {
      var trimmed = String(updates.name || "").trim()
      if (trimmed !== "") next.name = trimmed
    }
    if (updates && updates.settings !== undefined)
      next.settings = snapshotForLayout(updates.settings)
    list[i] = next
    break
  }
  return list
}

function removeLayoutPreset(savedLayouts, id) {
  var list = normalizeSavedLayouts(savedLayouts)
  var out = []
  for (var i = 0; i < list.length; i++) {
    if (list[i].id !== id) out.push(list[i])
  }
  return out
}

function findLayoutPreset(savedLayouts, id) {
  var list = normalizeSavedLayouts(savedLayouts)
  for (var i = 0; i < list.length; i++) {
    if (list[i].id === id) return list[i]
  }
  return null
}

function mergeSettings(pluginId, base, updates) {
  var merged = {}
  base = base || {}
  updates = updates || {}
  for (var key in base) merged[key] = base[key]
  for (var ukey in updates) merged[ukey] = updates[ukey]
  return readSettings(settingsToEntry(pluginId, merged))
}

function readSettings(entry) {
  entry = entry || {}
  var position = String(entry.position || "top-right")
  return {
    scale: clampScale(entry.scale !== undefined ? entry.scale : 1),
    hourScale: readTextScale(entry, "hourScale", null, 0.75),
    dateScale: readTextScale(entry, "dateScale", "hourScale"),
    subtimeScale: readTextScale(entry, "subtimeScale", "hourScale"),
    ringLabelScale: readTextScale(entry, "ringLabelScale", "scale"),
    minuteCapsuleScale: readTextScale(entry, "minuteCapsuleScale", "subtimeScale", 1.7),
    secondCapsuleScale: readTextScale(entry, "secondCapsuleScale", "subtimeScale"),
    hourColor: readColorOverride(entry, "hourColor"),
    dateColor: readColorOverride(entry, "dateColor"),
    minuteCapsuleColor: readColorOverride(entry, "minuteCapsuleColor"),
    secondCapsuleColor: readColorOverride(entry, "secondCapsuleColor"),
    minuteRingColor: readColorOverride(entry, "minuteRingColor"),
    secondRingColor: readColorOverride(entry, "secondRingColor"),
    ringLabelColor: readColorOverride(entry, "ringLabelColor"),
    hourFont: readFontOverride(entry, "hourFont"),
    dateFont: readFontOverride(entry, "dateFont"),
    minuteCapsuleFont: readFontOverride(entry, "minuteCapsuleFont"),
    secondCapsuleFont: readFontOverride(entry, "secondCapsuleFont"),
    showHour: entry.showHour !== false,
    showMinuteCapsule: entry.showMinuteCapsule !== false,
    showSecondCapsule: entry.showSecondCapsule !== false,
    showRingLabels: entry.showRingLabels !== false,
    showRings: entry.showRings !== false,
    hourOffsetX: clampOffset(entry.hourOffsetX, -40, 40),
    hourOffsetY: clampOffset(entry.hourOffsetY, -40, 40),
    dateOffsetX: clampOffset(entry.dateOffsetX, -40, 40),
    dateOffsetY: clampOffset(entry.dateOffsetY, -40, 40),
    minuteCapsuleAngleOffset: clampOffset(entry.minuteCapsuleAngleOffset, -90, 90, 12),
    secondCapsuleAngleOffset: clampOffset(entry.secondCapsuleAngleOffset, -90, 90, -18),
    minuteCapsuleRadiusOffset: clampOffset(entry.minuteCapsuleRadiusOffset, -40, 40, 1),
    secondCapsuleRadiusOffset: clampOffset(entry.secondCapsuleRadiusOffset, -40, 40),
    ringRotationOffset: clampOffset(entry.ringRotationOffset, -180, 180),
    position: position,
    centerLayout: resolveLayoutStyle(entry.centerLayout),
    use24h: entry.use24h === true,
    showSeconds: entry.showSeconds !== false,
    showDate: entry.showDate !== false,
    clockEnabled: entry.clockEnabled !== false,
    accentMode: String(entry.accentMode || "theme"),
    margin: clampMargin(entry.margin !== undefined ? entry.margin : 12),
    barPadding: Math.max(0, Math.round(Number(entry.barPadding) || 0)),
    clockFont: String(entry.clockFont || "Liberation Sans"),
    labelFont: String(entry.labelFont || "JetBrainsMono Nerd Font,JetBrainsMono NF"),
    ringDiameter: clampRingDiameter(entry.ringDiameter !== undefined ? entry.ringDiameter : 0.29),
    ringGap: clampRingGap(entry.ringGap !== undefined ? entry.ringGap : 57),
    ringArcDegrees: clampRingArcDegrees(entry.ringArcDegrees, position),
    ringTransparency: readRingTransparency(entry),
    screenMode: normalizeScreenMode(String(entry.screenMode || "all")),
    selectedMonitors: normalizeMonitorNames(entry.selectedMonitors),
    perMonitorScale: entry.perMonitorScale === true,
    scaleReferenceHeight: clampReferenceHeight(
      entry.scaleReferenceHeight !== undefined ? entry.scaleReferenceHeight : 1080
    ),
    savedLayouts: normalizeSavedLayouts(entry.savedLayouts)
  }
}

function settingsToEntry(pluginId, settings) {
  settings = settings || {}
  return {
    id: pluginId,
    scale: settings.scale,
    hourScale: settings.hourScale,
    dateScale: settings.dateScale,
    subtimeScale: settings.subtimeScale,
    ringLabelScale: settings.ringLabelScale,
    minuteCapsuleScale: settings.minuteCapsuleScale,
    secondCapsuleScale: settings.secondCapsuleScale,
    hourColor: settings.hourColor,
    dateColor: settings.dateColor,
    minuteCapsuleColor: settings.minuteCapsuleColor,
    secondCapsuleColor: settings.secondCapsuleColor,
    minuteRingColor: settings.minuteRingColor,
    secondRingColor: settings.secondRingColor,
    ringLabelColor: settings.ringLabelColor,
    hourFont: settings.hourFont,
    dateFont: settings.dateFont,
    minuteCapsuleFont: settings.minuteCapsuleFont,
    secondCapsuleFont: settings.secondCapsuleFont,
    showHour: settings.showHour,
    showMinuteCapsule: settings.showMinuteCapsule,
    showSecondCapsule: settings.showSecondCapsule,
    showRingLabels: settings.showRingLabels,
    showRings: settings.showRings,
    hourOffsetX: settings.hourOffsetX,
    hourOffsetY: settings.hourOffsetY,
    dateOffsetX: settings.dateOffsetX,
    dateOffsetY: settings.dateOffsetY,
    minuteCapsuleAngleOffset: settings.minuteCapsuleAngleOffset,
    secondCapsuleAngleOffset: settings.secondCapsuleAngleOffset,
    minuteCapsuleRadiusOffset: settings.minuteCapsuleRadiusOffset,
    secondCapsuleRadiusOffset: settings.secondCapsuleRadiusOffset,
    ringRotationOffset: settings.ringRotationOffset,
    position: settings.position,
    centerLayout: resolveLayoutStyle(settings.centerLayout),
    use24h: settings.use24h,
    showSeconds: settings.showSeconds,
    showDate: settings.showDate,
    clockEnabled: settings.clockEnabled,
    accentMode: settings.accentMode,
    margin: settings.margin,
    barPadding: settings.barPadding,
    clockFont: settings.clockFont,
    labelFont: settings.labelFont,
    ringDiameter: settings.ringDiameter,
    ringGap: settings.ringGap,
    ringArcDegrees: settings.ringArcDegrees,
    ringTransparency: settings.ringTransparency,
    minuteRingOpacity: settings.ringTransparency,
    secondRingOpacity: settings.ringTransparency,
    screenMode: settings.screenMode,
    selectedMonitors: (settings.selectedMonitors || []).slice(),
    perMonitorScale: settings.perMonitorScale,
    scaleReferenceHeight: settings.scaleReferenceHeight,
    savedLayouts: normalizeSavedLayouts(settings.savedLayouts)
  }
}

function screenReady(screen) {
  return !!(screen && screen.name && screen.width > 0 && screen.height > 0)
}

function barPosition(shell) {
  var barPos = ""
  if (shell && shell.barConfig) barPos = String(shell.barConfig.position || "")
  if (barPos === "" && shell && shell.bar && shell.bar.vertical !== undefined)
    barPos = shell.bar.vertical ? "right" : String(
      shell.barConfig ? shell.barConfig.position || "top" : "top"
    )
  return barPos || "top"
}

function barIsVertical(barPos, shell) {
  return barPos === "left" || barPos === "right"
    || !!(shell && shell.bar && shell.bar.vertical)
}

function edgeInsets(position, barPos, barVertical, clearance, manualPadding) {
  var insets = { top: 0, right: 0, bottom: 0, left: 0 }
  var pos = String(position || "middle-right")
  var onLeft = pos.indexOf("left") !== -1
  var onRight = pos.indexOf("right") !== -1
  var onTop = pos.indexOf("top") === 0
  var onBottom = pos.indexOf("bottom") === 0

  if (manualPadding > 0) {
    if (onTop) insets.top = manualPadding
    if (onBottom) insets.bottom = manualPadding
    if (onLeft) insets.left = manualPadding
    if (onRight) insets.right = manualPadding
    return insets
  }

  if (barPos === "top" && onTop) insets.top = clearance
  if (barPos === "bottom" && onBottom) insets.bottom = clearance
  if (barPos === "left" && onLeft) insets.left = clearance
  if ((barPos === "right" || barVertical) && onRight) insets.right = clearance
  return insets
}

function outerRadiusFromHeight(usableH, heightFit, labelPad, verticalInset, fallback) {
  if (usableH <= 0) return fallback
  return Math.round(usableH * heightFit - labelPad - verticalInset)
}

function borderMaxRadiusForPosition(usableW, usableH, labelPad, verticalInset, zone, layoutKind) {
  var borderMax = 0
  if (zone === "middle") {
    if (layoutKind === "left" || layoutKind === "right")
      borderMax = Math.round(usableH / 2 - labelPad - verticalInset * 0.25)
    else
      borderMax = Math.round(usableW / 2 - labelPad)
    if (layoutKind === "left" || layoutKind === "right")
      borderMax = Math.min(borderMax, Math.round(usableW - labelPad * 2))
  } else if (zone === "corner") {
    borderMax = Math.round(Math.min(usableW, usableH) - labelPad - verticalInset * 0.15)
  }
  return borderMax
}

function fitOuterRadiusForPosition(screenW, screenH, heightFit, labelPad, verticalInset, position, margin, insets) {
  var minR = 80
  var fallback = 160
  var pad = insets || { top: 0, right: 0, bottom: 0, left: 0 }
  var edge = Math.max(0, Number(margin) || 0)
  var usableW = Math.max(0, screenW - edge - pad.left - edge - pad.right)
  var usableH = Math.max(0, screenH - edge - pad.top - edge - pad.bottom)

  if (usableW <= 0 && usableH <= 0) return Math.max(minR, fallback)

  var zone = positionZone(position)
  var lk = parsePosition(position).layoutKind
  var preferred = outerRadiusFromHeight(usableH, heightFit, labelPad, verticalInset, fallback)
  var widthFactor = zone === "center" ? 2.15 : 2.65
  var fromW = usableW > 0
    ? Math.round((usableW - labelPad * 2) / widthFactor)
    : preferred
  preferred = Math.min(preferred, fromW)

  if (zone === "center") {
    var maxR = 240
    return Math.max(minR, Math.min(maxR, preferred))
  }

  var borderMax = borderMaxRadiusForPosition(usableW, usableH, labelPad, verticalInset, zone, lk)
  return Math.max(minR, Math.min(Math.max(minR, borderMax), preferred))
}

function positionZone(position) {
  var pos = String(position || "middle-right")
  if (pos === "middle-center") return "center"
  if (pos === "top-left" || pos === "top-right" || pos === "bottom-left" || pos === "bottom-right")
    return "corner"
  return "middle"
}

function hourInset(hourSize, labelPad) {
  var margin = Math.max(Math.round(labelPad * 0.5), 4)
  return hourSize / 2 + margin
}

function dateBlockHeight(use24h, dateScale, datePx, dayPx, ampmPx) {
  dateScale = clampTextScale(dateScale || 1)
  var spacing = Math.round(4 * dateScale)
  var h = Math.round(datePx * dateScale) + Math.round(dayPx * dateScale) + spacing
  if (!use24h) h += Math.round(ampmPx * dateScale) + spacing
  return h
}

function dateColumnHeight(use24h, dateScale) {
  return dateBlockHeight(use24h, dateScale, 11, 18, 10)
}

function centerDateBlockHeight(use24h, dateScale) {
  return dateBlockHeight(use24h, dateScale, 12, 20, 10)
}

function clockGeometry(position, outerRadius, labelPad, hourW, hourOnlyH, dateBelow, dateGap, dateH, labelBleed, columnLayout) {
  columnLayout = columnLayout || {}
  var dateInColumn = columnLayout.dateInColumn === true
  var dateColumnH = Number(columnLayout.dateColumnH) || 0
  var dateAboveHour = columnLayout.dateAboveHour === true
  var showSubtime = columnLayout.showCenterSubtime === true
  var hourSize = Number(columnLayout.hourSize) || hourOnlyH
  var columnSpacing = Math.round(Number(columnLayout.columnSpacing) || 10)
  var subtimeH = Number(columnLayout.subtimeH) || 0
  outerRadius = Number(outerRadius) || 0
  labelPad = Math.round(Number(labelPad) || 0)
  labelBleed = Math.round(Number(labelBleed) || 0)
  hourW = Number(hourW) || 0
  hourOnlyH = Number(hourOnlyH) || 0
  dateGap = Number(dateGap) || 0
  dateH = Number(dateH) || 0

  var R = outerRadius
  var edgePad = labelPad
  var bleed = Math.max(labelBleed, edgePad)
  var arcReach = R + bleed
  var needCx = hourInset(hourW, labelPad)
  var needCy = hourInset(hourOnlyH, labelPad)
  var fullSpan = R * 2 + bleed * 2
  var pos = parsePosition(position)
  var lk = pos.layoutKind
  var zone = pos.zone

  var dialW = fullSpan
  var dialH = fullSpan
  var cx = dialW / 2
  var cy = dialH / 2

  if (zone === "center") {
    cx = dialW / 2
    cy = dialH / 2
  } else if (zone === "middle") {
    if (lk === "left" || lk === "right") {
      dialH = fullSpan
      cy = dialH / 2
      if (lk === "left") {
        cx = needCx
        dialW = cx + arcReach
      } else {
        dialW = needCx + arcReach
        cx = dialW - needCx
      }
    } else {
      dialW = fullSpan
      cx = dialW / 2
      if (lk === "top") {
        cy = needCy
        dialH = cy + arcReach
      } else {
        dialH = needCy + arcReach
        cy = dialH - needCy
      }
    }
  } else {
    if (pos.alignH === "left") {
      cx = needCx
      dialW = cx + arcReach
    } else {
      dialW = needCx + arcReach
      cx = dialW - needCx
    }
    if (lk === "top") {
      cy = needCy
      dialH = cy + arcReach
    } else {
      dialH = needCy + arcReach
      cy = dialH - needCy
    }
  }

  var frame = {
    width: dialW,
    height: dialH,
    dialX: 0,
    dialY: 0,
    dialW: dialW,
    dialH: dialH,
    cx: cx,
    cy: cy,
    hourX: cx - hourW / 2,
    hourY: cy - hourOnlyH / 2
  }

  var aboveHour = 0
  var belowHour = 0
  if (dateInColumn && dateColumnH > 0) {
    if (dateAboveHour) aboveHour += dateColumnH + columnSpacing
    else belowHour += dateColumnH + columnSpacing
  }
  if (showSubtime && subtimeH > 0) {
    if (dateAboveHour) aboveHour += subtimeH + columnSpacing
    else belowHour += subtimeH + columnSpacing
  }

  if (aboveHour > 0 || belowHour > 0) {
    var columnY = cy - hourSize / 2 - aboveHour
    var stackBottom = cy + hourSize / 2 + belowHour
    if (columnY < edgePad) {
      var shift = edgePad - columnY
      dialH += shift
      cy += shift
      columnY += shift
      stackBottom += shift
      frame.dialH = dialH
      frame.cy = cy
    }
    frame.hourY = columnY
    frame.height = Math.max(dialH, stackBottom + edgePad)
  }

  if (dateBelow)
    frame.height = dialH + dateGap + dateH
  return frame
}

function clampPlacement(x, y, itemW, itemH, panelW, panelH) {
  var maxX = Math.max(0, panelW - itemW)
  var maxY = Math.max(0, panelH - itemH)
  return {
    x: Math.max(0, Math.min(x, maxX)),
    y: Math.max(0, Math.min(y, maxY))
  }
}

var SCREEN_MODES = ["all", "primary", "focused", "external", "selected"]

function normalizeScreenMode(value) {
  var mode = String(value || "all").toLowerCase()
  return SCREEN_MODES.indexOf(mode) >= 0 ? mode : "all"
}

function screenModeOptions() {
  return [
    { value: "all", label: "All monitors" },
    { value: "selected", label: "Custom — pick monitors below" },
    { value: "primary", label: "Primary (internal)" },
    { value: "focused", label: "Focused monitor only" },
    { value: "external", label: "External monitors only" }
  ]
}

function normalizeMonitorNames(names) {
  if (!names) return []
  if (!Array.isArray(names)) {
    var single = String(names || "").trim()
    return single === "" ? [] : [single]
  }
  var out = []
  for (var i = 0; i < names.length; i++) {
    var name = String(names[i] || "").trim()
    if (name !== "" && out.indexOf(name) < 0) out.push(name)
  }
  return out
}

function monitorListIncludes(list, name) {
  name = String(name || "")
  if (name === "") return false
  list = normalizeMonitorNames(list)
  for (var i = 0; i < list.length; i++) {
    if (list[i] === name) return true
  }
  return false
}

function shouldShowOnScreen(screen, mode, internalName, focusedName, selectedMonitors) {
  if (!screenReady(screen)) return false
  mode = normalizeScreenMode(mode)
  var name = String(screen.name || "")
  if (mode === "all") return true
  if (mode === "selected") {
    var picked = normalizeMonitorNames(selectedMonitors)
    if (picked.length === 0) return false
    return monitorListIncludes(picked, name)
  }
  if (mode === "focused")
    return focusedName !== "" && name === focusedName
  if (mode === "primary") {
    if (internalName !== "") return name === internalName
    return focusedName !== "" && name === focusedName
  }
  if (mode === "external") {
    if (internalName !== "") return name !== internalName
    return focusedName !== "" && name !== focusedName
  }
  return true
}

function perMonitorScaleFactor(userScale, screenHeight, enabled, referenceHeight) {
  if (!enabled) return userScale
  var ref = Number(referenceHeight)
  if (!isFinite(ref) || ref <= 0) ref = 1080
  var h = Number(screenHeight)
  if (!isFinite(h) || h <= 0) return userScale
  return userScale * (h / ref)
}

function clampReferenceHeight(value) {
  return clampNumber(value, 1080, 720, 2160, true)
}

function refreshRateForMonitor(mon) {
  if (!mon || !mon.lastIpcObject) return 60
  return normalizeRefreshRate(mon.lastIpcObject.refreshRate)
}

function normalizeRefreshRate(hz) {
  var n = Number(hz)
  if (!isFinite(n) || n <= 0) return 60
  return Math.max(30, Math.min(360, n))
}

var CANVAS_MAX_HZ = 60

function tickIntervalMs(refreshRateHz, lowPower, showSeconds) {
  if (lowPower) return 500
  if (showSeconds === false) return 1000
  var hz = Math.min(CANVAS_MAX_HZ, normalizeRefreshRate(refreshRateHz))
  return Math.max(16, Math.round(1000 / hz))
}

function formatRefreshRate(hz) {
  var n = normalizeRefreshRate(hz)
  return (Math.round(n * 10) / 10) + " Hz"
}

function needsInternalMonitorName(mode) {
  mode = normalizeScreenMode(mode)
  return mode === "primary" || mode === "external"
}

var _ringAngles = null

function ringAngles() {
  if (_ringAngles) return _ringAngles
  _ringAngles = []
  for (var i = 0; i < 60; i++)
    _ringAngles.push(i * (Math.PI * 2 / 60))
  return _ringAngles
}

function ringRotationRad(progress, focusAngle) {
  return focusAngle - progress * (Math.PI * 2 / 60)
}

function tickIndexAtWorldAngle(worldAngle, rotation) {
  var local = normalizeAngle0(worldAngle - rotation)
  var index = Math.round(local * 60 / (Math.PI * 2)) % 60
  if (index < 0) index += 60
  return index
}

function ringLabelAtWorldAngle(worldAngle, progress, focusAngle) {
  return pad2(tickIndexAtWorldAngle(worldAngle, ringRotationRad(progress, focusAngle)))
}

function minuteProgress(parts) {
  return parts.minuteFloat
}

function secondProgress(parts) {
  return parts.secondFloat
}

function parsePosition(position) {
  var pos = String(position || "middle-right")
  var layout = "right"
  if (pos === "middle-center") layout = "center"
  else if (pos.indexOf("top") === 0) layout = "top"
  else if (pos.indexOf("bottom") === 0) layout = "bottom"
  else if (pos.indexOf("left") !== -1) layout = "left"

  var alignH = "center"
  if (pos.indexOf("left") !== -1) alignH = "left"
  else if (pos.indexOf("right") !== -1) alignH = "right"

  var towardCenterH = 0
  var towardCenterV = 0
  if (pos.indexOf("left") !== -1) towardCenterH = 1
  else if (pos.indexOf("right") !== -1) towardCenterH = -1
  if (pos.indexOf("top") === 0) towardCenterV = 1
  else if (pos.indexOf("bottom") === 0) towardCenterV = -1

  var focusAngle = Math.PI
  if (pos !== "middle-center") {
    if (towardCenterH === 0 && towardCenterV === 0) focusAngle = Math.PI
    else focusAngle = Math.atan2(towardCenterV, towardCenterH)
  }

  var edgeSide = "center"
  if (pos.indexOf("left") !== -1) edgeSide = "left"
  else if (pos.indexOf("right") !== -1) edgeSide = "right"

  var verticalAlign = "middle"
  if (pos.indexOf("top") === 0) verticalAlign = "top"
  else if (pos.indexOf("bottom") === 0) verticalAlign = "bottom"

  return {
    layoutKind: layout,
    alignH: alignH,
    focusAngle: focusAngle,
    edgeSide: edgeSide,
    verticalAlign: verticalAlign,
    zone: positionZone(pos)
  }
}

function focusAngleForPosition(position) {
  return parsePosition(position).focusAngle
}

var LAYOUT_STYLES = ["orbit", "digital"]

var LEGACY_LAYOUT_ALIASES = {
  dial: "orbit",
  stack: "orbit",
  split: "orbit",
  arc: "orbit",
  minimal: "orbit",
  single: "orbit",
  "single-focus": "orbit",
  sunburst: "orbit"
}

function normalizeLayoutStyle(value) {
  var cl = String(value || "orbit").toLowerCase().replace(/_/g, "-")
  if (LEGACY_LAYOUT_ALIASES[cl]) cl = LEGACY_LAYOUT_ALIASES[cl]
  return LAYOUT_STYLES.indexOf(cl) >= 0 ? cl : "orbit"
}

function resolveLayoutStyle(layoutStyle) {
  if (layoutStyle === undefined || layoutStyle === null || layoutStyle === "")
    return "orbit"
  return normalizeLayoutStyle(layoutStyle)
}

function layoutStyleOptions() {
  return [
    { value: "orbit", label: "Orbit — minute/second capsules, position tunable in Components" },
    { value: "digital", label: "Digital — unified H:MM readout, small seconds, no rings" }
  ]
}

function applyLayoutStyle(spec, style) {
  if (!spec) return
  style = normalizeLayoutStyle(style)

  switch (style) {
    case "digital":
      spec.showCapsules = false
      spec.digitalReadout = true
      spec.hourSizeFactor = 1.12
      spec.dialSizeFactor = 0.55
      spec.showGuideRing = false
      spec.showRings = false
      break
    default:
      break
  }
}

function layoutSpec(position, layoutStyle, ringArcDegrees) {
  var pos = String(position || "middle-right")
  var focus = focusAngleForPosition(pos)
  var zone = positionZone(pos)
  var style = resolveLayoutStyle(layoutStyle)

  var spec = {
    variant: style,
    showCapsules: true,
    singleCapsule: false,
    digitalReadout: false,
    dateBelowDial: zone === "center",
    dateInHourColumn: zone !== "center",
    dateAboveHour: pos.indexOf("bottom") === 0,
    hourInDial: true,
    hourAtRingCenter: true,
    minuteCapsuleAngle: focus,
    secondCapsuleAngle: focus,
    focusAngle: focus,
    ringStrength: 1,
    hourSizeFactor: 1,
    dialSizeFactor: 1,
    showGuideRing: true,
    showRings: true,
    fullRing: false,
    arcFrom: null,
    arcTo: null,
    ringArcDegrees: clampRingArcDegrees(ringArcDegrees, pos)
  }

  applyPositionRingRules(spec, pos, ringArcDegrees)
  applyLayoutStyle(spec, style)
  return spec
}

function applyPositionRingRules(spec, position, ringArcDegrees) {
  if (!spec) return
  var zone = positionZone(position)
  var focus = focusAngleForPosition(position)
  var degrees = clampRingArcDegrees(ringArcDegrees, position)

  spec.hourAtRingCenter = true
  spec.hourInDial = true
  spec.ringArcDegrees = degrees

  if (degrees >= 360) {
    spec.fullRing = true
    spec.arcFrom = null
    spec.arcTo = null
    return
  }

  spec.fullRing = false
  var half = (degrees / 360) * Math.PI
  spec.arcFrom = focus - half
  spec.arcTo = focus + half
  spec.arcEmphasis = zone === "corner" || degrees <= 120
  spec.arcEdgeFade = spec.arcEmphasis ? 0.02 : 0.05
}

function resolvedArcBounds(spec) {
  if (!spec || spec.fullRing) return { from: NaN, to: NaN }
  if (arcBoundsActive(spec.arcFrom, spec.arcTo))
    return { from: spec.arcFrom, to: spec.arcTo }
  return { from: NaN, to: NaN }
}

function ringEdgeMeetFade(angle, arcFrom, arcTo, edge) {
  if (!isFinite(arcFrom) || !isFinite(arcTo)) return 1
  var t = angleOnArcT(angle, arcFrom, arcTo)
  if (t < 0) return 0
  if (edge === undefined || edge === null) edge = 0.05
  if (t < edge) return smoothstep(t / edge)
  if (t > 1 - edge) return smoothstep((1 - t) / edge)
  return 1
}

function smoothstep(t) {
  t = Math.max(0, Math.min(1, t))
  return t * t * (3 - 2 * t)
}

function capsuleRenderAngles(minuteAngle, secondAngle, singleCapsule) {
  if (singleCapsule) {
    return { minute: minuteAngle, second: secondAngle }
  }
  if (Math.abs(minuteAngle - secondAngle) < 0.001) {
    return { minute: minuteAngle - 0.14, second: secondAngle + 0.14 }
  }
  return { minute: minuteAngle, second: secondAngle }
}

function normalizeAngle0(angle) {
  var twoPi = Math.PI * 2
  while (angle < 0) angle += twoPi
  while (angle >= twoPi) angle -= twoPi
  return angle
}

function angleOnArcT(angle, arcFrom, arcTo) {
  if (arcFrom === null || arcTo === null) return 0.5
  if (!isFinite(arcFrom) || !isFinite(arcTo)) return 0.5
  angle = normalizeAngle0(angle)
  arcFrom = normalizeAngle0(arcFrom)
  arcTo = normalizeAngle0(arcTo)
  var span = arcTo - arcFrom
  if (span <= 0) span += Math.PI * 2
  if (span <= 0) return -1
  var rel = angle - arcFrom
  if (rel < 0) rel += Math.PI * 2
  if (rel > span) return -1
  return rel / span
}

function dotOnArc(angle, arcFrom, arcTo) {
  if (arcFrom === null || arcTo === null) return true
  if (!isFinite(arcFrom) || !isFinite(arcTo)) return true
  return angleOnArcT(angle, arcFrom, arcTo) >= 0
}

function arcBoundsActive(arcFrom, arcTo) {
  return arcFrom !== null && arcTo !== null && isFinite(arcFrom) && isFinite(arcTo)
}

function ringDotFade(index, progress, onFace) {
  var dist = Math.abs(((index - progress + 60) % 60) - 30)
  if (dist > 30) dist = 60 - dist
  return onFace ? Math.max(0.12, 1 - dist / 19) : 0.06
}

function ringDotAlpha(labeled, fade, onFace, strength) {
  var base = labeled ? 0.48 : 0.32
  if (!onFace) base = labeled ? 0.32 : 0.22
  return Math.min(1, (base + fade * (onFace ? 0.52 : 0.14)) * strength)
}

function isRingLabelVisible(angle, fullRing, arcFrom, arcTo) {
  if (fullRing) return true
  return dotOnArc(angle, arcFrom, arcTo)
}
