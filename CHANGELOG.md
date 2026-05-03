# RecklessTracker Changelog

## [v0.1.8] - 2026-05-03

### Changed

- Tracker visibility logic now shows the icon whenever configured filters pass, even with no active buff/cooldown (pre-use idle-ready state).
- Cooldown visualization switched to edge-only style for better icon saturation visibility.
- TOC interface line now includes `120001, 120005, 120007` for cross-build compatibility.
- Startup order now registers `/rt` slash commands before settings panel initialization.

### Fixed

- Idle-ready tracker icon now stays hidden on characters that do not have the configured potion in their bags.
- Reduced cooldown overlay darkness by disabling swipe fill (`SetDrawSwipe(false)`) to prevent the icon from looking blacked out.
- Improved timer readability by moving timer text to a dedicated layer above cooldown and using stronger text styling.
- Settings panel initialization is wrapped in `pcall` so settings failures do not break slash commands or core tracker startup.

### Added

- Optional TTS alerts for cooldown ready (`potion ready`) and buff end (`potion ended`), while keeping the 5-second warning on the existing sound path.
- Per-addon TTS voice selector in the settings panel, with saved voice fallback to WoW's current default voice when the selected voice is unavailable.
- Test-gated local pipeline:
  - `scripts/run-tests.ps1` (Pester checks for TOC compatibility + startup invariants)
  - `scripts/deploy-live.ps1` (runs tests first, blocks deploy on failure)
- Regression test that validates TOC includes the active client interface parsed from local `.build.info`.
- GitHub verification pipeline hardening:
  - Multi-job CI (`Verify`) with Lua lint, PowerShell tests, and packager dry-run.
  - Packaged zip content policy check + uploaded verification artifacts.
  - Release workflow now runs verification first and only publishes on success.

## [v0.1.1] - 2026-04-11

### Added

- Unlock-safe move mode (`MOVE`) so the frame can always be repositioned when unlocked.
- Icon scale controls via `/rt size <0.5-2.0>` and `/rt scale <value>`.
- Settings slider for icon scale.
- Cooldown pixel glow for the final 10 seconds.
- Configurable glow color (RGB) via `/rt glow <r> <g> <b>`.
- Settings sliders for glow red/green/blue values.
- ElvUI-esque visual styling pass (dark matte panel, crisp pixel borders, cleaner timer/label styling).

### Changed

- Updated TOC interface compatibility values for Midnight builds.
- Improved aura scan robustness and performance by validating/storing only safe numeric aura spell IDs and throttling fallback scans.

### Fixed

- Aura taint errors from protected/secret aura fields by removing `sourceUnit` comparisons, adding `issecretvalue`/`canaccesstable` guards, and using `HELPFUL|PLAYER` for fallback scans.
- `/rt item` now immediately refreshes cached potion metadata.
