# RecklessTracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Retail Midnight addon that tracks Potion of Recklessness buff duration/cooldown with configurable visibility by combat and content type.

**Architecture:** A single-file addon (`RecklessTracker.lua`) with four internal modules: state, UI, visibility filters, and configuration. It uses event-driven updates plus a lightweight ticker for smooth countdown text and one-shot alerts for buff warning and cooldown ready.

**Tech Stack:** WoW Lua API (Retail 12.0.5+), Blizzard Settings API, SavedVariables

---

## File Structure
- Create: `RecklessTracker/RecklessTracker.toc` (addon metadata + SavedVariables)
- Create: `RecklessTracker/RecklessTracker.lua` (core logic/UI/settings/slash commands)
- Create: `README.md` (install + usage + known limitations)

### Task 1: Scaffold Addon Files

**Files:**
- Create: `RecklessTracker/RecklessTracker.toc`
- Create: `RecklessTracker/RecklessTracker.lua`

- [ ] **Step 1: Add `.toc` metadata and SavedVariables declaration**

```toc
## Interface: 120005
## Title: RecklessTracker
## Notes: Tracks Potion of Recklessness duration and cooldown.
## Author: tekau + Codex
## Version: 0.1.0
## SavedVariables: RecklessTrackerDB

RecklessTracker.lua
```

- [ ] **Step 2: Add addon bootstrap and defaults table**

```lua
local ADDON_NAME = ...
local addon = CreateFrame("Frame")

local defaults = {
  locked = false,
  position = { x = 0, y = -180 },
  alerts = { buffWarn = true, cooldownReady = true },
  visibility = {
    inCombat = true,
    outOfCombat = true,
    world = true,
    dungeon = true,
    raid = true,
    pvp = true,
    delve = true,
  },
}
```

- [ ] **Step 3: Register startup event and slash command skeleton**

Run check: verify Lua loads with `/reload` and no startup error.

### Task 2: Implement State + Visibility Logic

**Files:**
- Modify: `RecklessTracker/RecklessTracker.lua`

- [ ] **Step 1: Implement potion state helpers**

```lua
-- cooldown via C_Item.GetItemCooldown(itemID)
-- buff via C_UnitAuras.GetPlayerAuraBySpellID(spellID)
```

- [ ] **Step 2: Implement content classification**

```lua
-- world / dungeon / raid / pvp / delve
-- delve uses C_DelvesUI.HasActiveDelve() when available
```

- [ ] **Step 3: Implement `ShouldShow()` combining combat + content toggles**

Run check: no Lua errors toggling combat and changing zones.

### Task 3: Build UI + Alerts

**Files:**
- Modify: `RecklessTracker/RecklessTracker.lua`

- [ ] **Step 1: Build movable icon frame with timer text and cooldown swipe**
- [ ] **Step 2: Add update/render loop (state-driven + lightweight ticker)**
- [ ] **Step 3: Add one-shot alerts**

```lua
-- buff warning at <= 5s once
-- cooldown ready flash + sound once
```

Run check: use potion and confirm timer transitions buff -> cooldown -> ready.

### Task 4: Settings Panel + Slash Commands + Docs

**Files:**
- Modify: `RecklessTracker/RecklessTracker.lua`
- Create: `README.md`

- [ ] **Step 1: Add Blizzard Settings checkboxes for all toggles**
- [ ] **Step 2: Add slash commands (`/rt`, `/rt lock`, `/rt test`)**
- [ ] **Step 3: Add README install and usage instructions**

Run check: `/rt` opens settings, options persist after `/reload`.

### Task 5: Final Verification

**Files:**
- Verify runtime behavior in game

- [ ] **Step 1: Run static scan for placeholders**

Run: `rg -n "TODO|TBD|FIXME|XXX" RecklessTracker README.md`
Expected: no unintended placeholders

- [ ] **Step 2: Confirm addon tree**

Run: `Get-ChildItem -Recurse RecklessTracker`
Expected: `.toc` and `.lua` present

- [ ] **Step 3: Prepare manual in-game validation checklist**

```text
/reload -> no Lua errors
Potion use -> buff timer + 5s alert
Buff ends -> cooldown shown
Cooldown ready -> READY flash + sound
Combat/content toggles respected
Position and toggles persist after /reload
```
