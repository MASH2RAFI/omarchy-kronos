.pragma library

var ACCENT_MODES = ["contrast", "accent", "theme", "mono"]

function normalizeAccentMode(value) {
  var mode = String(value || "contrast").toLowerCase()
  return ACCENT_MODES.indexOf(mode) >= 0 ? mode : "contrast"
}

function accentModeOptions() {
  return [
    { value: "contrast", label: "Contrast — rings opposite theme background" },
    { value: "accent", label: "Accent — rings and capsules use theme accent" },
    { value: "theme", label: "Theme — foreground and muted from palette" },
    { value: "mono", label: "Mono — foreground only" }
  ]
}

function luminance(color) {
  return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
}

function ringColorOpposingBackground(foreground, background) {
  var fgL = luminance(foreground)
  var bgL = luminance(background)
  if (Math.abs(fgL - bgL) > 0.06)
    return foreground
  return bgL > 0.5 ? Qt.rgba(0.06, 0.06, 0.06, 1) : Qt.rgba(0.96, 0.96, 0.96, 1)
}

function pickContrastingRings(foreground, background, accent, muted) {
  var fgL = luminance(foreground)
  var bgL = luminance(background)
  var lightTheme = fgL > bgL
  var ringPrimary = ringColorOpposingBackground(foreground, background)
  var capsuleFill = lightTheme ? background : foreground
  var capsuleText = lightTheme ? foreground : background

  return {
    minuteRing: ringPrimary,
    secondRing: ringPrimary,
    minuteCapsuleText: capsuleText,
    secondCapsuleText: capsuleText,
    capsuleFill: capsuleFill,
    capsuleBorder: ringPrimary
  }
}

function palette(mode, colors) {
  mode = normalizeAccentMode(mode)
  var fg = colors.foreground
  var bg = colors.background
  var muted = colors.muted
  var accent = colors.accent
  var ring = ringColorOpposingBackground(fg, bg)

  if (mode === "contrast") {
    var contrast = pickContrastingRings(fg, bg, accent, muted)
    return {
      hour: fg,
      subtime: muted,
      datePrimary: fg,
      dateMuted: muted,
      minuteRing: contrast.minuteRing,
      secondRing: contrast.secondRing,
      minuteCapsuleText: contrast.minuteCapsuleText,
      secondCapsuleText: contrast.secondCapsuleText,
      capsuleFill: contrast.capsuleFill,
      capsuleBorder: contrast.capsuleBorder
    }
  }

  if (mode === "mono") {
    return {
      hour: fg,
      subtime: fg,
      datePrimary: fg,
      dateMuted: fg,
      minuteRing: ring,
      secondRing: ring,
      minuteCapsuleText: fg,
      secondCapsuleText: fg,
      capsuleFill: bg,
      capsuleBorder: fg
    }
  }

  if (mode === "theme") {
    return {
      hour: fg,
      subtime: muted,
      datePrimary: fg,
      dateMuted: muted,
      minuteRing: ring,
      secondRing: ring,
      minuteCapsuleText: fg,
      secondCapsuleText: muted,
      capsuleFill: bg,
      capsuleBorder: fg
    }
  }

  return {
    hour: fg,
    subtime: muted,
    datePrimary: fg,
    dateMuted: muted,
    minuteRing: ring,
    secondRing: ring,
    minuteCapsuleText: accent,
    secondCapsuleText: muted,
    capsuleFill: bg,
    capsuleBorder: accent
  }
}

function applyOverrides(base, overrides) {
  var out = {}
  for (var key in base) out[key] = base[key]
  for (var okey in overrides) {
    var value = overrides[okey]
    if (value !== undefined && value !== null && value !== "") out[okey] = value
  }
  return out
}

function ink(color, alpha) {
  return Qt.rgba(color.r, color.g, color.b, alpha)
}
