<h1 align="center">Kronos</h1>

<p align="center"><strong>A big, beautiful orbital clock for your Omarchy wallpaper.</strong></p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.2.0-7aa2f7?style=flat-square" alt="Version 1.2.0" />
  <img src="https://img.shields.io/badge/Omarchy-4.x-89b4fa?style=flat-square" alt="Omarchy 4.x" />
  <img src="https://img.shields.io/badge/Wayland-Quickshell-bb9af7?style=flat-square&logo=wayland&logoColor=white" alt="Wayland / Quickshell" />
  <img src="https://img.shields.io/badge/QML-41CD52?style=flat-square&logo=qt&logoColor=white" alt="QML" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT license" /></a>
</p>

<p align="center"><img src="preview.png" alt="Kronos orbital clock on a space wallpaper" width="900"></p>

A third-party [Omarchy](https://omarchy.org) shell plugin that renders a large, deeply customizable desktop clock on your wallpaper. The default look pairs a bold hour numeral with two smooth orbital rings for minutes and seconds, inspired by terminal-style and Ryoku-like orbital layouts — or switch to a unified digital readout, and tune color, font, size, and position independently for every piece.

The clock lives on the wallpaper layer (below windows), respects the Omarchy bar when placed on the same edge, and adapts ring size to your monitor height.

```bash
omarchy plugin add https://github.com/MASH2RAFI/omarchy-kronos.git --enable
omarchy restart shell
```

**Contents:** [Preview](#preview) · [Features](#features) · [Requirements](#requirements) · [Installation](#installation) · [Configuration](#configuration) · [Multi-monitor](#multi-monitor) · [Performance](#performance) · [Uninstall](#uninstall) · [Settings reference](docs/settings-reference.md) · [Development](docs/development.md)

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
- **Smooth, light animation** — rings are drawn once and rotated on the GPU, capped at 60 Hz (once a second when the seconds ring is off or rings are hidden); optional **Low power** mode ticks twice a second
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

### Dependencies and privileges

Kronos runs unsandboxed inside `omarchy-shell` with your user permissions, like every Omarchy plugin. What it touches:

| What | When | Why |
|------|------|-----|
| `~/.config/omarchy/shell.json` | Read on change; written only when you change a setting in the panel or bar widget | Its own plugin entry — the same file the shell uses for every plugin |
| Hyprland IPC (via Quickshell) | Always | Monitor names, refresh rates and the focused monitor; the built-in (laptop) panel for **Show on** `primary` / `external` is recognised by its `eDP-` / `LVDS-` / `DSI-` connector name |

Kronos runs **no external commands or subprocesses**. No network access, no `sudo`, no background services, no install hooks, and no second Quickshell process. The only other dependency is build-time: `qt6-shadertools` (`qsb`), needed **only** to rebuild the shipped ring shader after editing it — see [Development](docs/development.md#shaders).

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
      "lowPower": false,
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

This example shows the common fields only. Per-component color, font, visibility, and position-offset keys (e.g. `hourColor`, `minuteCapsuleFont`, `showRings`, `dateOffsetX`) and `savedLayouts` are omitted here for brevity — see the [Settings reference](docs/settings-reference.md) for the complete list, or just use the GUI panel, which writes all of this for you.

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
| **General** | Position, layout style, saved layouts (add/apply/rename/delete), ring diameter, ring spacing, **ring arc**, ring transparency, seconds ring toggle, **low power** toggle, ring colors, 24h/date toggles |
| **Fonts & sizes** | Layout size, ring label size, hour/date/subtime/capsule sizes, hour & date font, ring label font |
| **Components** | Per-component color, font, visibility, and position (offset) overrides for the hour, date, minute capsule, second capsule, and rings/tick labels |
| **Monitors** | Per-output toggles, display presets, scale-per-monitor, edge margin, bar padding |

**General → Layout → Position** also resets **Ring arc** to that position's default (corner 120°, edge 180°, center 360°). Override with the arc slider afterward.

Each monitor has a **Show clock on this monitor** toggle; **Select all** / **Select none** are at the top of the Monitors tab.

### Bar widget

When the plugin is enabled, a **bar widget** is added to your Omarchy bar (default: center section, after the clock). Omarchy removes it automatically when you disable or uninstall the plugin.

| Action | Effect |
|--------|--------|
| **Left click** | Toggle the wallpaper clock on/off (`clockEnabled`). The icon is highlighted while the clock is hidden |
| **Right click** | Open settings |

Move it like any bar widget: `omarchy bar move mash2rafi.kronos --section center --after omarchy.clock`

You can also open settings from the terminal:

```bash
omarchy-shell shell summon mash2rafi.kronos "{}"
```

Close with **Esc**, clicking the scrim, or the **Close** button.

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

The clock uses Omarchy's standard **`Variants { model: Quickshell.screens }`** pattern — one wallpaper-layer surface per connected output. Each surface is only as large as the clock (plus a small click margin) and is placed by the compositor, so an animating clock never repaints the whole screen.

| Behavior | Detail |
|----------|--------|
| **One clock per monitor** | Every screen gets its own instance, positioned independently within that output |
| **Per-screen sizing** | Ring radius fits both the monitor's height **and** width (ultrawide, portrait, small laptop) |
| **Scaled & high-refresh outputs** | Ring textures are captured at the output's device pixel ratio, so labels stay sharp at 1.25×, 1.5× and 2×; the ring tick stays capped at 60 Hz on 120/144/240 Hz panels |
| **Bar insets** | Top/left/right/bottom bar clearance applies only when the clock anchor shares that edge |
| **Hotplug / layout changes** | `ScreenMoveRemap` hides the layer briefly while Hyprland moves outputs, then restores |
| **Placement clamp** | Clock is kept fully on-screen even when the combined dial + hour block is large; its reported size covers everything it draws (hour, date and offsets), so no position clips it |

There is no per-monitor position config — the same position and scale apply to all outputs, but each screen computes its own fit from its resolution. Open **Monitors** to toggle which outputs show the clock (always-visible toggles per output), set per-monitor scaling, edge margin, and bar padding. Use **Quick preset** for all monitors, focused, primary/internal, or external-only rules.

## Performance

The clock runs **inside quickshell** (same process as the bar and other shell plugins) — there is no separate clock process.

Since **1.2.0** each ring's 60 dots and 00–59 labels are rasterised **once** (`ShaderRingCanvas.qml`) and a small fragment shader (`shaders/ringmask.frag`) rotates them and applies the fade, so a clock tick only updates a rotation angle — no per-frame canvas painting or text rasterisation. The clock's layer surface is also sized to the clock rather than the whole screen, so each tick no longer makes Quickshell and Hyprland redraw an entire (possibly 4K) output. Text and the minute ring update once a second.

| Mode | Ring tick |
|------|-----------|
| Orbit with seconds ring | Smooth, capped at **60 Hz** (also on high-refresh monitors) |
| Seconds ring off | **1 Hz** |
| Digital layout / rings hidden | **4 Hz** (keeps the seconds readout on time) |
| **Low power** on | **2 Hz** |

Measured on an Intel iGPU with three outputs (3072×1920 @120 at 2×, 3840×2160 @119.88 at 1.5×, 1920×1080), default orbit layout with seconds:

| | 1.1.0 | 1.2.0 |
|---|---|---|
| GPU busy (whole GPU) | ~96% | ~46% |
| Hyprland GPU time | 10.4 s/s | 1.2 s/s |
| Quickshell CPU (clock + shell) | ~127% of one core | ~18% of one core |

Figures vary with hardware, monitor count and layout. With **Low power** on, or the seconds ring off, the clock's cost is close to zero. To sample quickshell's live CPU and memory use over a few seconds (`ps` `%CPU` is a lifetime average):

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

**Lowest cost:** turn on **Low power** or turn off **Seconds ring** (General tab).

**If rings or placement misbehave on your hardware,** two advanced keys (not in the GUI) restore the pre-1.2 behaviour — see the [Settings reference](docs/settings-reference.md#advanced-troubleshooting):

```json
"renderer": "canvas",
"compactSurface": false
```

The canvas renderer is also used automatically if the ring shader can't be loaded on your system.

## Development

The project layout, reload and validation steps, debugging tips and architecture notes are in [docs/development.md](docs/development.md). Bug reports and pull requests are welcome.

## Uninstall

```bash
omarchy plugin remove mash2rafi.kronos
```

This works for every install method. It disables the plugin (which removes its `shell.json` entry and bar widget), unloads it from the running shell, and then:

| Installed with | What `remove` does to the folder |
|----------------|----------------------------------|
| `omarchy plugin add` (Option A) | Deletes the git checkout; the repo stays on GitHub |
| Symlink (Option B) | Removes only the link; your clone is untouched |
| Copy (Option C) | Moves it to a `.mash2rafi.kronos.bak.<timestamp>` backup in the plugins folder |

No shell restart is needed. Saved layouts and other settings live in the plugin's `shell.json` entry, so they go with it.

## License

MIT — see [LICENSE](LICENSE).
