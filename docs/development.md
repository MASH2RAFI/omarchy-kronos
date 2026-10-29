# Developing Kronos

Back to the [README](../README.md).

## Project layout

```
omarchy-kronos/
├── manifest.json          # Plugin metadata and settings schema
├── preview.png            # Marketplace preview screenshot
├── docs/                  # Extra reference screenshots for README
│   ├── reference-light-wallpaper.png
│   └── reference-dark-layers.png
├── Service.qml            # Layer-shell window, placement, config wiring
├── BarWidget.qml          # Bar toggle + settings shortcut
├── ClockFace.qml          # Clock UI: rings, capsules, hour, date
├── RingCanvas.qml         # Ring dial front: picks the shader or canvas renderer
├── ShaderRingCanvas.qml   # Default renderer: rings rasterised once, rotated by a shader
├── LegacyRingCanvas.qml   # Canvas renderer (fallback / renderer: "canvas")
├── shaders/
│   ├── ringmask.frag      # Ring rotate + world-angle fade shader (source)
│   ├── ringmask.frag.qsb  # Compiled shader shipped with the plugin
│   └── ringmask.frag.sha256  # Source hash, checked by tools/build-shaders.sh --check
├── tools/
│   └── build-shaders.sh   # Rebuild / check the .qsb files
├── CHANGELOG.md
├── DateColumn.qml         # Shared date/weekday/AM-PM column
├── TimeCapsule.qml        # Minute/second pill capsule
├── ShellConfigWatcher.qml # Reads shell.json directly; live-updates around a host caching limitation
├── PluginConfig.js        # Shared shell.json plugin entry helpers
├── SettingsPanel.qml      # GUI settings overlay (panel entry point)
├── SettingsSlider.qml     # Reusable labeled slider row for settings
├── ColorField.qml         # Hex color override field + swatch for settings
├── FontDropdown.qml       # Scrollable font picker for settings
├── FontOptions.js         # Curated clock/label font lists
├── ClockModel.js          # Time formatting, layout geometry, ring math, settings read/write
├── ClockTheme.js          # Theme palette mapping (contrast/accent/theme/mono) + override merging
├── README.md
└── LICENSE
```

## Reload after changes

If the plugin directory is symlinked, save files and run:

```bash
omarchy restart shell
```

Or rescan without a full restart:

```bash
omarchy-shell shell rescanPlugins
```

## Validating changes

Before deploying, per the [Omarchy plugin development guide](https://plugins.omarchy.org/develop.html):

```bash
omarchy plugin validate ~/Projects/omarchy-kronos
qmllint -I /usr/share/omarchy/shell ~/Projects/omarchy-kronos/*.qml
```

Both should exit clean (no output, exit code 0). `qmllint` also works without `-I` (it just can't resolve `qs.Commons`/`qs.Ui` types then, so it checks less).

### Shaders

The ring shader ships precompiled (`shaders/ringmask.frag.qsb`, built for SPIR-V, GLSL 100 es/120/150, HLSL and MSL). After editing `shaders/*.frag`, rebuild it — this needs `qsb` from `qt6-shadertools` (`sudo pacman -S qt6-shadertools`, or point `QSB=/path/to/qsb` at one):

```bash
tools/build-shaders.sh          # rebuild every .qsb and record its source hash
tools/build-shaders.sh --check  # exit 1 if a .frag changed without a rebuild — run before release
```

Commit the `.frag`, `.qsb` and `.sha256` together. If a `.qsb` is missing or broken, Kronos logs `Kronos: ring shader unavailable, using canvas renderer` and keeps working on the canvas renderer.

## Debugging

Check recent shell logs for plugin errors:

```bash
journalctl --user --since "5 min ago" --no-pager | rg -i "kronos|SettingsPanel|SettingsSlider|load failed"
```

Rescan plugins and open the settings panel from the terminal:

```bash
omarchy-shell shell rescanPlugins
omarchy-shell shell summon mash2rafi.kronos "{}"
```

Common issues:

| Symptom | Fix |
|---------|-----|
| Clock not visible | QML load error — check logs above |
| Settings won't open | QML error in panel — look for `SettingsPanel` / `SettingsSlider` / `FontDropdown` in logs |
| Settings change but clock doesn't update | Should update live within ~2s via `ShellConfigWatcher.qml` (no restart needed); if it doesn't, check `~/.config/omarchy/shell.json` parses as valid JSON — a parse failure keeps the last good value |
| Clock under bar | Increase **Edge margin** or **Bar padding** (Monitors tab) |
| Rings too large/small | **Ring diameter** or **Layout size** (General / Fonts & sizes) |
| Wrong arc span | **Ring arc** on General tab; changing position resets arc to default |
| Hour/date/subtime too large/small | **Fonts & sizes** tab |
| Ring labels too large/small | **Ring label size** on Fonts & sizes tab |
| High CPU / GPU usage | Turn on **Low power** or turn off the seconds ring — see [Performance](../README.md#performance) |
| Rings missing, garbled, or `ring shader unavailable` in logs | Set `"renderer": "canvas"`; if the `.qsb` was edited, run `tools/build-shaders.sh` |
| Clock misplaced or not clickable on one output | Set `"compactSurface": false` to use the pre-1.2 full-screen surface, and report the monitor setup |

## Architecture notes

- **`Service.qml`** — one bottom-layer `PanelWindow` per monitor; reads normalized settings from `Clock.readSettings()` via a `cfg` object, sourced through a `ShellConfigWatcher` (see below); applies bar-aware placement and per-monitor layout scale. By default (`compactSurface`) the surface is only the clock plus its click padding, positioned by layer-shell anchors + margins (padding shrinks against an edge so margins never go negative, and the surface is capped at the output size); with `compactSurface: false` it is a full-screen surface and `placeClock()` positions the clock inside it. Right-click summons the settings panel.
- **`SettingsPanel.qml`** — panel entry point: four-tab overlay with live preview. Uses a single `draft` settings object updated through `patchDraft()` → `Clock.mergeSettings()` → `shell.updateEntryInline()`. Also reads its initial state through `ShellConfigWatcher` so reopening the panel never shows stale values.
- **`ShellConfigWatcher.qml`** — works around a host limitation: the scoped shell object plugins receive (`services/PluginShellApi.qml` in the Omarchy shell) sets `barConfig` once at creation via a plain value (`barConfig: shell.publicBarConfig()`, not `Qt.binding(...)`), and that scoped object is cached for the plugin's whole lifetime keyed only by static capabilities — so it never reflects settings-panel edits made afterward, only a full shell restart does. This component reads `~/.config/omarchy/shell.json` directly with `watchChanges: true` instead, so both `Service.qml` and `SettingsPanel.qml` see edits within ~2 seconds with no restart.
- **`SettingsSlider.qml`** — reusable labeled slider row (`import qs.Ui` for `PanelSlider`). Used on General, Fonts & sizes, and Components tabs. Same-directory QML components load by type name — no extra import line needed in the panel.
- **`ColorField.qml`** — hex color override field: swatch + validated text input + an **Auto** button that clears back to `""` (theme-derived). Used throughout the Components tab.
- **`ClockFace.qml`** — composes rings, hour/date column, and capsules. Layout/text scales are independent properties; ring arc comes from `Clock.layoutSpec(position, centerLayout, ringArcDegrees)`; per-component color/font overrides are merged in via `Theme.applyOverrides()`. Time has two rates: `timeMs` follows the ring tick (`Clock.tickIntervalMs`), while text, the date and the minute ring bind to the whole-second `secondMs`. The digital layout measures its text, and `Clock.clockGeometry()` grows the face's box wherever the drawn hour/date column (plus offsets) would spill past it, so edge placement never clips the clock.
- **`RingCanvas.qml`** — ring dial front end with independent minute/second dot colors and label colors, separate `labelScale` (tick labels) and `chromeScale` (guide strokes), a `showLabels` toggle, and arc clipping via `arcFrom` / `arcTo`. A `Loader` picks the renderer from `renderer` and forwards every property to it; `repaint()` re-rasterises after geometry/colour/font changes and `tick()` runs on each clock tick.
- **`ShaderRingCanvas.qml`** — default renderer. Each ring is painted once into a Canvas in ring-local space at full opacity and captured by a static `ShaderEffectSource` (at the screen's device pixel ratio). The per-dot alpha depends only on world angle, so it is baked into a 1440×1 lookup texture built from the same `ClockModel` fade functions; `shaders/ringmask.frag` rotates the ring texture and multiplies by that lookup. Emits `failed` if the shader doesn't load, which makes `RingCanvas` switch to the canvas renderer.
- **`LegacyRingCanvas.qml`** — the pre-1.2 renderer: one Canvas repainting both rings every tick.
- **`ClockModel.js`** — `.pragma library` module: time parts, `readSettings` / `mergeSettings` / `settingsToEntry`, placement geometry, layout specs, arc rules, ring math, and the saved-layout preset functions (`saveLayoutPreset`, `applyLayoutSnapshot`, `updateLayoutPreset`, `removeLayoutPreset`).
- **`ClockTheme.js`** — `accentMode` palette mapping (contrast / accent / theme / mono) plus `applyOverrides()` for layering per-component color overrides on top of it.
- **`PluginConfig.js`** — `entryOrDefault()` and `defaultSettings()` helpers, plus `findEntryInBarConfig()` (the raw-object lookup `ShellConfigWatcher` and `findBarEntry` both use).
- **`FontDropdown.qml`** + **`FontOptions.js`** — scrollable font picker and curated font lists.
- **`DateColumn.qml`** / **`TimeCapsule.qml`** — shared date block and MM/SS capsule widgets.

