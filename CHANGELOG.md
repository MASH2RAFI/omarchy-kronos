# Changelog

## 1.2.0

### Performance
- Rings are rasterised once and rotated on the GPU by a small shader (`shaders/ringmask.frag`) instead of repainting the whole ring canvas — 120 rotated `fillText` calls — on every tick. Kronos falls back to the canvas renderer automatically if the shader can't load.
- Each clock's layer surface is sized to the clock instead of covering the whole screen, so ticks no longer make Quickshell and Hyprland redraw entire outputs.
- Text, date and the minute ring update once a second; the fast tick only drives the seconds ring.
- No 60 Hz tick when no rings are drawn (digital layout, rings hidden).
- Measured on three outputs (2×, 1.5× and 1× scale): whole-GPU busy time ~96% → ~46%, Hyprland GPU time ~9× lower, Quickshell CPU ~7× lower.

### Added
- **Low power** toggle (`lowPower`) in the settings panel and manifest schema: the rings tick twice a second.
- Advanced troubleshooting keys `renderer` (`shader` / `canvas`) and `compactSurface` (`true` / `false`) to restore the 1.1 behaviour on problem hardware.
- `tools/build-shaders.sh` to rebuild and check the shipped shader.

### Changed
- Kronos no longer runs any external command. The **Show on** `primary` / `external` modes used to poll `omarchy-monitor-state` every 5 seconds; the built-in panel is now recognised directly from its `eDP-` / `LVDS-` / `DSI-` connector name, so it also updates the moment a monitor is plugged in.
- The bar icon is now highlighted while the clock is **hidden** and plain while it's showing (previously the reverse), so a switched-off clock stands out.

### Fixed
- The bar icon could show the wrong on/off state, and toggle from it, after the clock was switched on or off elsewhere (settings panel, `shell.json`). It now reads the live config like the clock itself.
- With the bar on the **left**, clocks on the right edge were pushed an extra bar-width away from the screen edge.
- The digital layout could be clipped at some positions: its box didn't account for the real text size, the readout width, or hour/date offsets.
- Orbit layouts at bottom positions hung the hour numeral below the clock's box, where the screen edge could cut it off.
- In middle-center, the date was placed below the clock's box instead of inside it.
- Ring textures are captured at the output's device pixel ratio, so labels stay sharp on scaled outputs.
