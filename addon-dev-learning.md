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

8. Claimed release readiness before validating the full GitHub -> CurseForge publish path.
- Impact: packaging uploaded successfully but workflow still failed on GitHub release creation, causing confusion.

9. Pinned CI to `Pester 3.4.0` without accounting for runner module-signing/publisher checks.
- Impact: CI failed before tests executed after runner image updates.

10. Mixed verification/runtime edits in one working tree without explicitly separating push scope at first.
- Impact: risk of pushing gameplay/runtime changes when user requested CI-only updates.

11. Defined Pester `Assert-*` helper functions at the top of `tests/RecklessTracker.Tests.ps1`. Local Pester 3 ran them fine; GitHub's Pester 5 evaluates top-level code only during Discovery and the helpers are invisible to `It` blocks during Run, so every CI test failed with `CommandNotFoundException`.
- Impact: every release run from v0.1.8 through the first v0.1.12 attempt failed verify-before-publish for ~32 days, blocking CurseForge uploads.

12. Claimed the v0.1.12 release was shipped before reading the workflow conclusion. Tag pushed, packager run still in flight — verify-before-publish silently failed and no artifact reached CurseForge.
- Impact: false "released" claim; required force-retag once the Pester 5 issue was fixed.

## Root Causes

1. No enforced RED->GREEN loop at the beginning.
2. No deploy barrier between source edits and live addon files.
3. Over-reliance on assumptions instead of observable runtime errors/stacks.
4. Insufficient startup hardening in UI creation path.
5. No explicit release-verification gate in the workflow checklist.
6. No explicit selective-staging protocol for partial pushes.
7. Local Pester 3 hid the Pester 5 Discovery/Run scope split — no parity check between local and CI Pester versions.
8. Treated `git push origin v<tag>` as the end of "release", instead of "release ends when the workflow logs `Success!`".

## Non-Negotiable Rules (Future Turns)

1. No live deploy without passing tests.
2. No behavior changes without at least one failing test first.
3. No speculative patches when a stack trace exists; fix the exact failing path.
4. Guard render/update paths against partially initialized UI state.
5. Wrap risky startup steps (`CreateTrackerFrame`, settings registration) in `pcall` with explicit chat diagnostics.
6. Verify TOC interface values against local client metadata (`.build.info`) and in-game `GetBuildInfo()`.
7. Keep fixes minimal and scoped to the proven root cause.
8. No release claim without a successful tagged release run and log evidence of CurseForge upload success.
9. When user asks for partial push (for example CI only), stage explicit file paths only, then verify commit file list with `git show --name-only` before push.
10. Pester helper functions (`Assert-*`, fixtures, etc.) live in `tests/Assertions.ps1` or another file dot-sourced from each `Describe`'s `BeforeAll`. NEVER define them at the top of a `.Tests.ps1` file — Pester 5 will not see them in `It` blocks and every CI test will fail with `CommandNotFoundException`. Local Pester 3.4.0 hides this; the only authoritative check is the CI run.
11. After `git push origin <tag>`, wait for the Release workflow to complete (`gh run view <id> --json conclusion`). A `success` conclusion plus `Uploading … Success!` in the package-and-publish log are required before claiming the release is done. CurseForge's public Files page can lag by several minutes after `Success!`; that lag is normal and does not warrant re-releasing.
12. When `verify-before-publish` fails on a tag that produced no artifact, force-retag the same version on the fix commit (`git tag -d v<x.y.z>` → `git push origin :refs/tags/v<x.y.z>` → tag → push). Only bump the version if artifacts already shipped under the failed tag.

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

CI verification gates:

1. `.github/workflows/ci.yml` (`Verify`) runs:
- Lua lint (`luacheck`)
- Pester tests
- BigWigs packager dry-run (`-d`) plus packaged-zip content policy checks
2. `.github/workflows/release.yml` runs verification before publish and only uploads when verification succeeds.
3. Release publish job is attached to environment `curseforge-production` for optional approval/protection rules.
4. CI should not pin fragile legacy test tooling versions when newer runner images can break installation/signing.
5. Tests must support both local and CI environments (for example `.build.info` fixture fallback and `RT_BUILD_INFO_PATH` override).

## Source Control Safeguards

When pushing only a subset of changes:

1. Use explicit path staging (`git add <file1> <file2> ...`) rather than `git add .`.
2. Confirm staged scope (`git status --short`) before commit.
3. After commit, verify final committed files (`git show --name-only -1`).
4. Confirm excluded files remain local and uncommitted.

## CurseForge Release Pipeline Baseline

1. GitHub repo: `marvin-pedlar/reckless-tracker`.
2. Release workflow: `.github/workflows/release.yml` on tag push `v*`.
3. Required repo secrets:
   - `CF_API_KEY`
   - `CF_PROJECT_ID`
4. `GITHUB_OAUTH` must remain unset for packager runs to avoid false-failed workflows from GitHub release creation permissions.
5. Internal/confidential files must stay excluded via `.pkgmeta` ignores (docs/scripts/tests/internal notes).
6. Release verification must include:
   - `gh run list -R marvin-pedlar/reckless-tracker`
   - `gh run view <run-id> --log`
   - explicit log evidence containing upload `Success!`.
7. If CurseForge web/API verification is blocked by Cloudflare/permissions, treat GitHub release logs as the authoritative automation proof and call out the remaining manual UI check.

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
