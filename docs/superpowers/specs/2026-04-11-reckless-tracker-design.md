# RecklessTracker Design Spec

Date: 2026-04-11
Target Client: WoW Retail Midnight (12.0.5+)
Addon Name: RecklessTracker

## Goal
Build a lightweight World of Warcraft addon that tracks Potion of Recklessness buff duration and potion cooldown with configurable visibility rules by combat state and content type.

## Scope
In scope:
- Movable icon tracker with numeric timer and cooldown swipe
- Potion buff duration tracking
- Potion cooldown tracking
- Alert at 5s buff remaining
- Alert when potion cooldown is ready
- Visibility toggles for combat state and content type
- Blizzard Settings panel plus slash commands
- SavedVariables persistence

Out of scope:
- Tracking multiple potion families at once
- Group/raid sharing or external comms
- Per-spec profiles

## User Experience
- Default display is a small movable icon with timer text.
- When Potion of Recklessness buff is active, the timer shows buff remaining.
- When buff is not active but potion is on cooldown, the timer shows cooldown remaining.
- When neither applies, the frame hides (except test mode).
- Alerts:
  - Play sound once at 5s buff remaining.
  - Show READY flash text and play ready sound once when cooldown finishes.

## Configuration
Blizzard Settings category: RecklessTracker

Toggles:
- Show In Combat
- Show Out of Combat
- Show in Open World
- Show in Dungeons/Mythic+
- Show in Raids
- Show in PvP
- Show in Delves
- Buff warning sound enabled
- Cooldown ready sound enabled
- Lock frame

Slash commands:
- /rt -> opens settings panel
- /rt lock -> toggles frame lock
- /rt test -> temporary preview state

## Data Model
SavedVariables table: RecklessTrackerDB

Fields:
- position: { x, y }
- locked: boolean
- alerts:
  - buffWarn: boolean
  - cooldownReady: boolean
- visibility:
  - inCombat: boolean
  - outOfCombat: boolean
  - world: boolean
  - dungeon: boolean
  - raid: boolean
  - pvp: boolean
  - delve: boolean

## Technical Design
Files:
- RecklessTracker/RecklessTracker.toc
- RecklessTracker/RecklessTracker.lua

Core subsystems:
1. Event Controller
2. State Resolver
3. UI Renderer
4. Settings/Slash Handler

### API compatibility (Retail Midnight)
- Aura lookup: C_UnitAuras.GetPlayerAuraBySpellID
- Cooldown lookup: C_Item.GetItemCooldown (legacy fallback only if needed)
- Events: PLAYER_LOGIN, UNIT_AURA, BAG_UPDATE_COOLDOWN, SPELL_UPDATE_COOLDOWN, PLAYER_REGEN_DISABLED, PLAYER_REGEN_ENABLED, ZONE_CHANGED_NEW_AREA

### Content Type Detection
Map current location to one category:
- Open world (non-instance)
- Dungeon/Mythic+ (instanceType = party)
- Raid (instanceType = raid)
- PvP (instanceType = arena or pvp)
- Delve (scenario/delve flags when available)

Visibility rule:
- show = combatTogglePass AND contentTogglePass

## Runtime Flow
1. On login, load defaults and saved data.
2. Build frame and register events.
3. On relevant events:
   - Recompute buff state
   - Recompute cooldown state
   - Recompute visibility state
   - Render icon/timer/sweep
4. Trigger one-shot alerts based on state transitions.

## Error Handling and Safety
- If APIs return nil/missing values, treat as inactive state.
- If potion item not found in bags, still track cooldown by item ID when API supports it.
- If content classification is ambiguous, fallback to Open World behavior.

## Test Plan
Manual in-game checks:
1. /reload: frame initializes with defaults.
2. Use potion: buff timer starts and decrements.
3. Near 5s remaining: warning sound plays once.
4. Buff ends: cooldown display continues.
5. Cooldown completion: READY flash and sound once.
6. Toggle each combat and content setting: verify show/hide behavior.
7. Enter open world, dungeon, raid, PvP, and delve: verify category filtering.
8. Move frame, /reload: position persists.
9. /rt, /rt lock, /rt test commands work.

## Approach Decision
Selected approach: Hybrid event-driven + lightweight periodic text refresh.
Reason: maintains efficient state updates while keeping countdown text smooth.

## Acceptance Criteria
- Accurate buff and cooldown tracking for Potion of Recklessness.
- Alerts fire exactly once at configured moments.
- Visibility respects both combat and content toggles.
- Settings persist and can be edited in Blizzard Settings.
- Addon runs without Lua errors on Retail Midnight client.
