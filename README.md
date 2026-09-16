# Kronos

A third-party [Omarchy](https://omarchy.org) shell plugin that renders a large, deeply customizable desktop clock on your wallpaper. The default look pairs a bold hour numeral with two smooth orbital rings for minutes and seconds, inspired by terminal-style and Ryoku-like orbital layouts — or switch to a unified digital readout, and tune color, font, size, and position independently for every piece.

The clock lives on the wallpaper layer (below windows), respects the Omarchy bar when placed on the same edge, and adapts ring size to your monitor height.

## Preview

All shots use `top-right` with a vertical bar — hour against the bar, rings curving inward, minute/second capsules at the focus.

| Space wallpaper | Light wallpaper | Dark layered wallpaper |
| --- | --- | --- |
| ![Kronos on a space wallpaper](preview.png) | ![Kronos on a light minimal wallpaper](docs/reference-light-wallpaper.png) | ![Kronos on a dark layered wallpaper](docs/reference-dark-layers.png) |
| **Contrast** rings on a busy background | **Mono** rings on a minimal background | Full rings with tick labels on a dark theme |

`preview.png` is the marketplace listing image. Additional reference shots live in [`docs/`](docs/).

## Features

- **Large hour display** with optional date block (short date, weekday, AM/PM)
- **Two orbital dot rings** with numeric labels at every tick (00–59)
  - Inner ring: minutes (smooth rotation)
  - Outer ring: seconds (smooth rotation)
- **Individual capsules** for `MM` and `SS` — independent size, color, font, visibility, and angle/radius position offsets per capsule (**Components** tab)
- **Per-component customization** — hour, date, minute capsule, second capsule, and rings/tick labels each get their own color override, font override, visibility toggle, and position nudge, independent of the global theme (**Components** tab)
- **Saved layouts** — name and save your current look, then apply/rename/update/delete it later; switch between full presets without losing your monitor setup (**General** tab)
- **Multi-monitor** — one wallpaper-layer clock per output; each screen sizes and positions independently (portrait, ultrawide, mixed resolutions)
- **Screen-aware sizing** — outer ring scales from each monitor's width and height (default ~40% of screen height, adjustable 25–55%)
- **Bar-aware placement** — auto-insets from the Omarchy bar on the anchored edge, per screen
- **Smooth animation** — ring repaints capped at 60 Hz (1 Hz when seconds are off)
- **Theme integration** — uses Omarchy palette (`foreground`, `background`, `muted`, `accent`) with live theme updates; **Contrast** mode draws rings opposite the theme background for wallpaper visibility
- **Ring transparency** — single slider fades both rings (0–100%)
- **Independent sizing** — layout, ring geometry, text, and fonts are separate controls (see [Sizing](#sizing))
- **Configurable ring arc** — show 30°–360° of the dial, centered on the focus (defaults by position)
- **GUI settings panel** — right-click to open; **General**, **Fonts & sizes**, **Components**, and **Monitors** tabs, live preview, **Reset to defaults**, instant save to `shell.json`
- **Layout styles** — two presentation styles (orbit, digital) at **any** screen position, with per-capsule angle/radius offsets for full position control; focus direction and border hugging follow position

## Requirements

- **Omarchy 4.x** with shell plugins enabled
- **Wayland** session (Quickshell layer-shell surface)
- Fonts used by default (optional but recommended):
  - `Liberation Sans` — hour and date
  - `JetBrainsMono Nerd Font` — ring labels (falls back to system mono)

## Installation

### Option A — Omarchy plugin command (recommended)

```bash
omarchy plugin add https://github.com/MASH2RAFI/omarchy-kronos.git --enable
omarchy restart shell
```

### Option B — Symlink (development)

```bash
git clone https://github.com/MASH2RAFI/omarchy-kronos.git ~/Projects/omarchy-kronos

ln -sfn ~/Projects/omarchy-kronos \
  ~/.config/omarchy/plugins/mash2rafi.kronos

omarchy plugin enable mash2rafi.kronos
omarchy restart shell
```

### Option C — Copy into plugins directory

```bash
git clone https://github.com/MASH2RAFI/omarchy-kronos.git
cp -r omarchy-kronos ~/.config/omarchy/plugins/mash2rafi.kronos
omarchy plugin enable mash2rafi.kronos
omarchy restart shell
```

The plugin id **must** match the directory name: `mash2rafi.kronos`.

## Configuration

Add or edit the plugin entry in `~/.config/omarchy/shell.json`:

```json
{
  "plugins": [
    {
      "id": "mash2rafi.kronos",
      "scale": 1,
      "hourScale": 0.75,
      "dateScale": 1,
      "subtimeScale": 1,
      "ringLabelScale": 1,
      "position": "top-right",
      "centerLayout": "orbit",
      "use24h": false,
      "showSeconds": true,
      "showDate": true,
      "accentMode": "theme",
      "ringDiameter": 0.29,
      "ringGap": 57,
      "ringArcDegrees": 0,
      "ringTransparency": 1,
      "screenMode": "all",
      "selectedMonitors": [],
      "margin": 12,
      "barPadding": 0,
      "clockFont": "Liberation Sans",
      "labelFont": "JetBrainsMono Nerd Font,JetBrainsMono NF"
    }
  ]
}
```

This example shows the common fields only. Per-component color, font, visibility, and position-offset keys (e.g. `hourColor`, `minuteCapsuleFont`, `showRings`, `dateOffsetX`) and `savedLayouts` are omitted here for brevity — see the [Settings reference](#settings-reference) for the complete list, or just use the GUI panel, which writes all of this for you.

After editing `shell.json`:

```bash
omarchy-shell shell rescanPlugins
omarchy restart shell
```

### Settings menu (GUI)

Right-click the clock on your wallpaper to open the settings overlay (layer-shell popup — floats above windows, not a tiled Hyprland window). Changes apply immediately and are saved to `shell.json`.

The panel has four tabs with a **sticky live preview** at the top. Changes apply immediately via `shell.updateEntryInline()` and are written to `shell.json`. Font pickers use a scrollable dropdown (`FontDropdown`) when the list is longer than six rows.

| Tab | Controls |
|-----|----------|
| **General** | Position, layout style, saved layouts (add/apply/rename/delete), ring diameter, ring spacing, **ring arc**, ring transparency, seconds ring toggle, ring colors, 24h/date toggles |
| **Fonts & sizes** | Layout size, ring label size, hour/date/subtime/capsule sizes, hour & date font, ring label font |
| **Components** | Per-component color, font, visibility, and position (offset) overrides for the hour, date, minute capsule, second capsule, and rings/tick labels |
| **Monitors** | Per-output toggles, display presets, scale-per-monitor, edge margin, bar padding |

**General → Layout → Position** also resets **Ring arc** to that position's default (corner 120°, edge 180°, center 360°). Override with the arc slider afterward.

Each monitor has a **Show clock on this monitor** toggle; **Select all** / **Select none** are at the top of the Monitors tab.

### Bar widget

When the plugin is enabled, a **bar widget** is added to your Omarchy bar (default: center section, after the clock). Omarchy removes it automatically when you disable or uninstall the plugin.

| Action | Effect |
|--------|--------|
| **Left click** | Toggle the wallpaper clock on/off (`clockEnabled`) |
| **Right click** | Open settings |

Move it like any bar widget: `omarchy bar move mash2rafi.kronos --section center --after omarchy.clock`

You can also open settings from the terminal:

```bash
omarchy-shell shell summon mash2rafi.kronos "{}"
```

Close with **Esc**, clicking the scrim, or the **Close** button.

### Settings reference

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `scale` | number | `1` | Layout size — capsule chrome and dial padding (`0.5`–`2.5`) |
| `hourScale` | number | `0.75` | Hour numeral (`0.5`–`2.5`) |
| `dateScale` | number | `1` | Date block (`0.5`–`2.5`) |
| `subtimeScale` | number | `1` | Legacy — no current layout shows a separate subtime line |
| `minuteCapsuleScale` | number | `1.7` | Minute capsule chrome and text (`0.5`–`2.5`) |
| `secondCapsuleScale` | number | `1` | Seconds capsule chrome and text (`0.5`–`2.5`) |
| `ringLabelScale` | number | `1` | Ring tick labels 00–59 (`0.5`–`2.5`) |
| `position` | string | `top-right` | Screen anchor — see [Positions](#positions) |
| `centerLayout` | string | `orbit` | Layout style — see [Layout styles](#layout-styles) |
| `use24h` | boolean | `false` | 24-hour hour label |
| `showSeconds` | boolean | `true` | Show outer seconds ring and capsule |
| `clockEnabled` | boolean | `true` | Master visibility toggle (bar widget) |
| `showDate` | boolean | `true` | Show date block under the hour |
| `accentMode` | string | `theme` | Ring colors — `contrast` (opposite theme bg), `accent`, `theme` (foreground/muted), `mono` |
| `ringDiameter` | number | `0.29` | Outer ring size (% of screen height, 25–55%) — independent of layout size |
| `ringGap` | number | `57` | Gap between minute and seconds rings (px) — independent of layout size |
| `ringArcDegrees` | number | `0` | Visible ring arc (30–360°). `0` = position default (corner 120°, edge 180°, center 360°) |
| `minuteCapsuleAngleOffset` | number | `12` | Minute capsule angle nudge, degrees (`-90`–`90`) |
| `secondCapsuleAngleOffset` | number | `-18` | Seconds capsule angle nudge, degrees (`-90`–`90`) |
| `minuteCapsuleRadiusOffset` | number | `1` | Minute capsule radius nudge, px (`-40`–`40`) |
| `secondCapsuleRadiusOffset` | number | `0` | Seconds capsule radius nudge, px (`-40`–`40`) |
| `ringRotationOffset` | number | `0` | Rotates which tick sits at the dial focus, degrees (`-180`–`180`); doesn't move the arc or capsules |
| `ringTransparency` | number | `1` | Ring visibility for both rings (0–100%) |
| `screenMode` | string | `all` | Quick preset — `all`, `selected` (custom picks), `primary`, `focused`, `external` |
| `selectedMonitors` | list | `[]` | Monitor names when using custom selection (set via Monitors tab toggles) |
| `perMonitorScale` | boolean | `false` | Scale clock size by each monitor height |
| `scaleReferenceHeight` | number | `1080` | Reference height (px) for per-monitor scaling |
| `margin` | number | `12` | Distance from screen edge (px) |
| `barPadding` | number | `0` | Extra inset from bar; `0` = auto-detect |
| `clockFont` | string | `Liberation Sans` | Hour and date font |
| `labelFont` | string | `JetBrainsMono Nerd Font,…` | Ring tick label font |
| `savedLayouts` | list | `[]` | Named appearance presets (`{id, name, settings}`); managed from the **General** tab, not hand-edited |

#### Per-component overrides (Components tab)

All color keys are `#RRGGBB` hex strings; empty (`""`) means "use the theme." All font keys are font-family strings; empty means "match the clock/label font." All are independent per component — none affect any other component.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `showHour` | boolean | `true` | Show the hour numeral |
| `hourColor` | string | `""` | Overrides the theme-derived hour color |
| `hourFont` | string | `""` | Overrides the clock font for the hour numeral only |
| `hourOffsetX` / `hourOffsetY` | number | `0` | Nudges the hour+date+subtime stack, px (`-40`–`40`) |
| `dateColor` | string | `""` | Overrides the weekday-line color; the muted date/AM-PM lines stay theme-derived |
| `dateFont` | string | `""` | Overrides both date fonts (weekday and date/AM-PM lines) |
| `dateOffsetX` / `dateOffsetY` | number | `0` | Nudges the date block, px (`-40`–`40`) |
| `showMinuteCapsule` / `showSecondCapsule` | boolean | `true` | Show that capsule, independent of layout style / seconds |
| `minuteCapsuleColor` / `secondCapsuleColor` | string | `""` | Overrides that capsule's text color |
| `minuteCapsuleFont` / `secondCapsuleFont` | string | `""` | Overrides that capsule's font |
| `showRings` | boolean | `true` | Show the ring dial (dots + labels + guide) at all |
| `showRingLabels` | boolean | `true` | Show the 00–59 tick labels; dots stay visible either way |
| `minuteRingColor` / `secondRingColor` | string | `""` | Overrides that ring's dot color |
| `ringLabelColor` | string | `""` | Overrides both rings' tick-label color; empty matches each ring's own dot color |

Omitted keys fall back sensibly: `dateScale` / `subtimeScale` inherit `hourScale`; `ringLabelScale` inherits `scale`; `minuteCapsuleScale` / `secondCapsuleScale` inherit `subtimeScale` on first load.

### Sizing

All size sliders are **independent** — changing one does not change the others.

| Control | Key | Tab | Affects |
|---------|-----|-----|---------|
| Layout size | `scale` | Fonts & sizes | Capsule pill chrome, guide strokes, dial padding |
| Ring diameter | `ringDiameter` | General | Outer radius (% screen height, 25–55%) |
| Ring spacing | `ringGap` | General | Pixel gap between minute and seconds rings |
| Ring arc | `ringArcDegrees` | General | Visible arc in degrees (360° = full circle) |
| Ring label size | `ringLabelScale` | Fonts & sizes | 00–59 tick labels on the rings |
| Hour size | `hourScale` | Fonts & sizes | Large hour numeral |
| Date size | `dateScale` | Fonts & sizes | Date and weekday block |
| Minute capsule size | `minuteCapsuleScale` | Fonts & sizes | Minute capsule chrome and text |
| Second capsule size | `secondCapsuleScale` | Fonts & sizes | Seconds capsule chrome and text |
| Subtime size (legacy) | `subtimeScale` | Fonts & sizes | No current layout shows a separate subtime line — kept as a fallback default for `minuteCapsuleScale`/`secondCapsuleScale` on older configs |

`perMonitorScale` (Monitors tab) only multiplies **layout size** (`scale`) by monitor height — not ring diameter, text sizes, or arc.

### Positions

`position` accepts any of:

`top-left`, `top-center`, `top-right`, `middle-left`, `middle-center`, `middle-right`, `bottom-left`, `bottom-center`, `bottom-right`

The first segment controls vertical alignment; `left` or `right` in the name sets which screen edge the hour hugs.

**Suggested setup:** `middle-right` with a right-side vertical bar.

Ring geometry is driven by **position** (focus direction and border hugging). **Ring arc** sets how many degrees of the dial are visible (30–360°), centered on that focus.

| Position type | Examples | Default arc |
|---------------|----------|-------------|
| Center | `middle-center` | **360°** full dial |
| Middle edge | `middle-left`, `middle-right`, `top-center`, `bottom-center` | **180°** |
| Corner | `top-left`, `top-right`, `bottom-left`, `bottom-right` | **120°** |

Changing **Position** resets the arc slider to that default. Set **Ring arc** on the General tab to override (30–360°). Store `0` or omit `ringArcDegrees` in `shell.json` to keep position-based defaults on load.

The hour sits at the center of the rings at every position. **Ring diameter** scales the outer radius as a percentage of screen height (25–55%), capped by each position's border-to-border maximum.

### Layout styles

`centerLayout` controls **presentation only** — capsules, subtime placement, ring visibility/weight, and guide ring visibility. Ring focus and border hugging follow `position`; arc span is set by **Ring arc**.

| Style | Description |
|-------|-------------|
| `orbit` | Default — minute/second capsules, with position tunable per-capsule (angle + radius) in the **Components** tab |
| `digital` | Unified `H:MM` readout at one size with small trailing seconds; rings and guide ring hidden, dial footprint tightened |

The former `sunburst` style (capsules spread to the arc ends) is now just `orbit` with wide capsule angle offsets — set the minute/second capsule angle offset sliders in **Components** toward ±90° to recreate it.

Legacy values in `shell.json` are mapped automatically to `orbit`: `dial`, `split`, `arc`, `stack`, `minimal`, `single`, `single-focus`, `sunburst`.

### Component customization

The **Components** tab holds per-component overrides for five pieces — **Hour**, **Date**, **Minute capsule**, **Second capsule**, and **Rings & tick labels** — each in its own card with whichever of these apply:

- **Color** — a hex override (`#RRGGBB`) with a live swatch and an **Auto** button to clear it back to the theme-derived color.
- **Font** — a dropdown of the same curated font list used elsewhere; the first option is always "Auto" (match the clock/label font).
- **Visibility** — an independent show/hide toggle (e.g. you can hide the seconds ring while keeping the seconds capsule, or vice versa).
- **Position** — a small nudge: pixel offsets for hour/date, angle + radius offsets for each capsule, or a rotation offset for the ring ticks.

These are pure overrides layered on top of everything else — `accentMode`, `scale`, `hourScale`, etc. still apply normally to anything you haven't overridden here. Size controls for these same pieces live on **Fonts & sizes**, not here, to avoid duplicating the same setting in two tabs.

Position overrides are intentionally small (nudges, not free placement) — the clock's layout is one global `position` anchor plus a relative-layout engine that places every piece relative to the dial, so unbounded offsets risk pushing content past the screen edge. If you need one component noticeably far from its default spot, `position` and `centerLayout` are the bigger levers; the Components offsets are for fine-tuning.

### Saved layouts

The **General** tab has a **Saved layouts** section for managing named appearance presets:

| Action | Effect |
|--------|--------|
| **Save current as new layout** | Snapshots everything about the current look under a name you choose |
| **Apply** | Replaces your current settings with that layout's snapshot |
| **Update with current** | Overwrites a saved layout with whatever the clock looks like right now |
| **Rename** | Changes just the layout's name |
| **Delete** | Removes the saved layout |

A layout snapshot is appearance only — it deliberately excludes `screenMode`, `selectedMonitors`, `perMonitorScale`, `scaleReferenceHeight`, and `clockEnabled`, so applying a saved look never moves the clock to a different monitor or turns it off. Layouts are stored in `savedLayouts` in `shell.json` and aren't affected by **Reset to defaults**, which only resets the current look.

## Multi-monitor

The clock uses Omarchy's standard **`Variants { model: Quickshell.screens }`** pattern — one full-screen wallpaper layer per connected output, same as the background and notification plugins.

| Behavior | Detail |
|----------|--------|
| **One clock per monitor** | Every screen gets its own instance, positioned independently within that output |
| **Per-screen sizing** | Ring radius fits both the monitor's height **and** width (ultrawide, portrait, small laptop) |
| **Bar insets** | Top/left/right/bottom bar clearance applies only when the clock anchor shares that edge |
| **Hotplug / layout changes** | `ScreenMoveRemap` hides the layer briefly while Hyprland moves outputs, then restores |
| **Placement clamp** | Clock is kept fully on-screen even when the combined dial + hour block is large |

There is no per-monitor position config — the same position and scale apply to all outputs, but each screen computes its own fit from its resolution. Open **Monitors** to toggle which outputs show the clock (always-visible toggles per output), set per-monitor scaling, edge margin, and bar padding. Use **Quick preset** for all monitors, focused, primary/internal, or external-only rules.

## Performance

The clock runs **inside quickshell** (same process as the bar and other shell plugins) — there is no separate clock process.

Rings are drawn with **`RingCanvas.qml`** — 60 ticks per ring, labeled 00–59 at every tick. Repaints are capped at **60 Hz** (even on high-refresh monitors) and drop to **~1 Hz** when the seconds ring is off. The settings preview uses a slower tick (`lowPower`) to save CPU while editing.

| | Omarchy shell + clock | Omarchy shell only | Clock delta (approx.) |
|---|---|---|---|
| **RAM** | ~480 MB | ~415 MB | **~60 MB** |
| **CPU** | ~15–20% of one core | ~13% | **~2–8% of one core** |

These figures vary by monitor count, layout, and whether the seconds ring is on. `ps` `%CPU` is a **lifetime average** — for a live reading, sample over a few seconds:

```bash
python3 - <<'PY'
import os, time
pid = int(os.popen("pgrep -x quickshell").read())
ncpu = os.cpu_count()
def pt():
    p = open(f"/proc/{pid}/stat").read().split()
    return int(p[13]) + int(p[14])
def st():
    return sum(int(x) for x in open("/proc/stat").read().splitlines()[0].split()[1:8])
rss = next(l for l in open(f"/proc/{pid}/status") if l.startswith("VmRSS:"))
p0, s0 = pt(), st(); time.sleep(3); p1, s1 = pt(), st()
cpu = 100 * (p1 - p0) / (s1 - s0) * ncpu
print(rss, f"CPU: {cpu:.1f}% of one core (~{cpu/ncpu:.1f}% of all cores)")
PY
```

Turn off **Seconds ring** (General tab) for the lowest CPU use (~1 repaint/sec).

## Development

### Project layout

```
omarchy-kronos/
├── manifest.json          # Plugin metadata and settings schema
├── preview.png            # Marketplace preview screenshot
├── docs/                  # Extra reference screenshots for README
│   ├── reference-light-wallpaper.png
│   └── reference-dark-layers.png
├── Service.qml            # Layer-shell window, placement, config wiring
├── BarWidget.qml          # Bar toggle + settings shortcut
├── ClockFace.qml   # Clock UI: rings, capsules, hour, date
├── RingCanvas.qml         # 60-tick ring dial (minute + second rings)
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

### Reload after changes

If the plugin directory is symlinked, save files and run:

```bash
omarchy restart shell
```

Or rescan without a full restart:

```bash
omarchy-shell shell rescanPlugins
```

### Validating changes

Before deploying, per the [Omarchy plugin development guide](https://plugins.omarchy.org/develop.html):

```bash
omarchy plugin validate ~/Projects/omarchy-kronos
qmllint -I /usr/share/omarchy/shell ~/Projects/omarchy-kronos/*.qml
```

Both should exit clean (no output, exit code 0). `qmllint` also works without `-I` (it just can't resolve `qs.Commons`/`qs.Ui` types then, so it checks less).

### Debugging

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
| High CPU usage | Expected with seconds ring on — see [Performance](#performance) |

### Architecture notes

- **`Service.qml`** — one bottom-layer `PanelWindow` per monitor; reads normalized settings from `Clock.readSettings()` via a `cfg` object, sourced through a `ShellConfigWatcher` (see below); applies bar-aware placement and per-monitor layout scale. Right-click summons the settings panel.
- **`SettingsPanel.qml`** — panel entry point: four-tab overlay with live preview. Uses a single `draft` settings object updated through `patchDraft()` → `Clock.mergeSettings()` → `shell.updateEntryInline()`. Also reads its initial state through `ShellConfigWatcher` so reopening the panel never shows stale values.
- **`ShellConfigWatcher.qml`** — works around a host limitation: the scoped shell object plugins receive (`services/PluginShellApi.qml` in the Omarchy shell) sets `barConfig` once at creation via a plain value (`barConfig: shell.publicBarConfig()`, not `Qt.binding(...)`), and that scoped object is cached for the plugin's whole lifetime keyed only by static capabilities — so it never reflects settings-panel edits made afterward, only a full shell restart does. This component reads `~/.config/omarchy/shell.json` directly with `watchChanges: true` instead, so both `Service.qml` and `SettingsPanel.qml` see edits within ~2 seconds with no restart.
- **`SettingsSlider.qml`** — reusable labeled slider row (`import qs.Ui` for `PanelSlider`). Used on General, Fonts & sizes, and Components tabs. Same-directory QML components load by type name — no extra import line needed in the panel.
- **`ColorField.qml`** — hex color override field: swatch + validated text input + an **Auto** button that clears back to `""` (theme-derived). Used throughout the Components tab.
- **`ClockFace.qml`** — composes rings, hour/date column, and capsules. Layout/text scales are independent properties; ring arc comes from `Clock.layoutSpec(position, centerLayout, ringArcDegrees)`; per-component color/font overrides are merged in via `Theme.applyOverrides()`.
- **`RingCanvas.qml`** — Canvas ring dial with independent minute/second dot colors and label colors, separate `labelScale` (tick labels) and `chromeScale` (guide strokes), and a `showLabels` toggle. Arc clipping via `arcFrom` / `arcTo`.
- **`ClockModel.js`** — `.pragma library` module: time parts, `readSettings` / `mergeSettings` / `settingsToEntry`, placement geometry, layout specs, arc rules, ring math, and the saved-layout preset functions (`saveLayoutPreset`, `applyLayoutSnapshot`, `updateLayoutPreset`, `removeLayoutPreset`).
- **`ClockTheme.js`** — `accentMode` palette mapping (contrast / accent / theme / mono) plus `applyOverrides()` for layering per-component color overrides on top of it.
- **`PluginConfig.js`** — `entryOrDefault()` and `defaultSettings()` helpers, plus `findEntryInBarConfig()` (the raw-object lookup `ShellConfigWatcher` and `findBarEntry` both use).
- **`FontDropdown.qml`** + **`FontOptions.js`** — scrollable font picker and curated font lists.
- **`DateColumn.qml`** / **`TimeCapsule.qml`** — shared date block and MM/SS capsule widgets.

## Uninstall

```bash
omarchy plugin disable mash2rafi.kronos
rm ~/.config/omarchy/plugins/mash2rafi.kronos   # skip if symlink — remove link only
omarchy restart shell
```

Remove the plugin block from `~/.config/omarchy/shell.json` if you added one.

## License

MIT — see [LICENSE](LICENSE).
