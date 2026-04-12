# Addon Dev Learning

This file tracks mistakes made during RecklessTracker development and the concrete practices required for future turns.

## Mistakes Made

1. Changed TOC interface compatibility without grounding it in the active client build.
- Impact: addon was flagged incompatible and did not load.

2. Deployed fixes directly to live addon folder without a mandatory test gate.
- Impact: repeated regressions reached the game client.

3. Registered slash commands before frame creation was proven healthy, while command handlers still called `Render()` unguarded.
- Impact: `/rt unlock` could crash with `ui.frame == nil`.

4. Allowed frame initialization to fail silently except for downstream symptoms.
- Impact: user saw secondary errors instead of primary startup failure.

5. Set `FontString:SetText()` before `SetFont()` for `statusText`.
- Impact: `FontString:SetText(): Font not set` and frame init aborted.

6. Introduced risky cooldown recovery logic without isolated verification.
- Impact: tracking reliability regressed.

7. Spent turns on speculative fixes instead of forcing root-cause evidence first.
- Impact: user time and trust were wasted.

## Root Causes

1. No enforced RED->GREEN loop at the beginning.
2. No deploy barrier between source edits and live addon files.
3. Over-reliance on assumptions instead of observable runtime errors/stacks.
4. Insufficient startup hardening in UI creation path.

## Non-Negotiable Rules (Future Turns)

1. No live deploy without passing tests.
2. No behavior changes without at least one failing test first.
3. No speculative patches when a stack trace exists; fix the exact failing path.
4. Guard render/update paths against partially initialized UI state.
5. Wrap risky startup steps (`CreateTrackerFrame`, settings registration) in `pcall` with explicit chat diagnostics.
6. Verify TOC interface values against local client metadata (`.build.info`) and in-game `GetBuildInfo()`.
7. Keep fixes minimal and scoped to the proven root cause.

## Current Verification Pipeline

Run tests:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
```

Deploy to live only through gated script:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-live.ps1
```

The deploy script must fail closed (no file copy) if tests fail.

## Required Test Coverage Baseline

1. TOC compatibility includes active client interface.
2. Slash command registration exists.
3. Initialize order keeps slash availability safe.
4. Settings init is protected by `pcall`.
5. Frame creation is protected by `pcall`.
6. `Render()` safely returns if UI frame is unavailable.
7. `statusText` font is set before text assignment.

## Working Agreement

If a regression appears:

1. Capture first error line + stack.
2. Add failing test for that exact regression.
3. Implement minimal fix.
4. Re-run tests.
5. Deploy through gated script only.

