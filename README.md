# RecklessTracker

RecklessTracker is a World of Warcraft Retail addon that tracks `Potion of Recklessness` buff duration and cooldown.

## Features
- Movable potion icon tracker with numeric countdown
- Buff duration display while active
- Cooldown display when buff is inactive
- Optional sound alert at 5s buff remaining
- Optional READY flash + sound when cooldown finishes
- Optional TTS alerts for `potion ready` and `potion ended`
- Visibility filters:
  - In combat / out of combat
  - Open world
  - Dungeons/Mythic+
  - Raids
  - PvP
  - Delves
- Blizzard Settings panel integration

## Installation
1. Close WoW.
2. Copy the folder `RecklessTracker` into:
   - `World of Warcraft\_retail_\Interface\AddOns\`
3. Start WoW and enable `RecklessTracker` in the AddOns list.
4. Use `/reload` after login.

Final path should look like:
`World of Warcraft\_retail_\Interface\AddOns\RecklessTracker\RecklessTracker.lua`

## Commands
- `/rt` - open settings
- `/rt lock` - toggle frame drag lock
- `/rt unlock` - force unlock the frame for dragging
- `/rt size <0.5-2.0>` - set icon scale (alias: `/rt scale <value>`)
- `/rt glow <r> <g> <b>` - set glow color (`0.0` to `1.0` per channel)
- `/rt test` - run a 20s preview mode
- `/rt item <itemID>` - set potion item ID (default `241289`)
- `/rt aura <spellID>` - set aura spell override (`0` clears override)
- `/rt status` - print active item/aura IDs

## Notes
- TOC compatibility list currently includes `120001`, `120005`, and `120007`.
- Active client interface should be verified with `/dump select(4, GetBuildInfo())`.
- Uses `C_Item.GetItemCooldown` for cooldown and `C_UnitAuras.GetPlayerAuraBySpellID` with fallback aura scan for buff detection.
- If Blizzard changes IDs in future builds, use `/rt item` and `/rt aura`.

## Test-Driven Pipeline
Run tests before every deploy:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
```

If your WoW install is not on `F:\`, point tests at another `.build.info` path:

```powershell
$env:RT_BUILD_INFO_PATH="D:\Games\World of Warcraft\.build.info"
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
```

Deploy to live AddOns only through the gated script (it runs tests first and refuses deploy on failures):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-live.ps1
```

## CI/Release Verification
- `Verify` workflow (push/PR):
  - Lua lint (`luacheck`)
  - Pester tests
  - Packager dry-run with package content policy checks
- `Release` workflow (tag `v*`):
  - Runs verification first
  - Publishes to CurseForge only if verification succeeds

## In-Game Validation Checklist
- `/reload` loads without Lua errors
- Drinking potion shows buff timer
- At 5s remaining, warning sound fires once
- After buff ends, cooldown countdown is shown
- With TTS alerts enabled, buff end announces `potion ended`
- At cooldown ready, READY flash and ready sound fire once
- With TTS alerts enabled, cooldown ready announces `potion ready` instead of the ready sound
- Combat/content toggles correctly control visibility
- Frame position and options persist across `/reload`
