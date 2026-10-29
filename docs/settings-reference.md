# Kronos settings reference

Every key Kronos reads from its plugin entry in `~/.config/omarchy/shell.json`. The GUI settings panel writes all of these for you. Back to the [README](../README.md).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `scale` | number | `1` | Layout size — capsule chrome and dial padding (`0.5`–`2.5`) |
| `hourScale` | number | `0.75` | Hour numeral (`0.5`–`2.5`) |
| `dateScale` | number | `1` | Date block (`0.5`–`2.5`) |
| `subtimeScale` | number | `1` | Legacy — no current layout shows a separate subtime line |
| `minuteCapsuleScale` | number | `1.7` | Minute capsule chrome and text (`0.5`–`2.5`) |
| `secondCapsuleScale` | number | `1` | Seconds capsule chrome and text (`0.5`–`2.5`) |
| `ringLabelScale` | number | `1` | Ring tick labels 00–59 (`0.5`–`2.5`) |
| `position` | string | `top-right` | Screen anchor — see [Positions](../README.md#positions) |
| `centerLayout` | string | `orbit` | Layout style — see [Layout styles](../README.md#layout-styles) |
| `use24h` | boolean | `false` | 24-hour hour label |
| `showSeconds` | boolean | `true` | Show outer seconds ring and capsule |
| `lowPower` | boolean | `false` | Tick the rings twice a second instead of animating smoothly (lighter on the GPU); a device setting, not saved into layouts |
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

## Advanced (troubleshooting)

Not shown in the GUI and not captured by saved layouts. Both default to the fast 1.2 behaviour; set them only to work around a problem on specific hardware.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `renderer` | string | `shader` | `shader` — rings drawn once and rotated on the GPU. `canvas` — the pre-1.2 renderer that repaints every tick. Kronos also falls back to `canvas` automatically (with one log warning) if the ring shader can't load. |
| `compactSurface` | boolean | `true` | `true` — each clock's layer surface is sized to the clock. `false` — the pre-1.2 full-screen transparent surface. |

## Per-component overrides (Components tab)

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

