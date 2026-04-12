local ADDON_NAME = ...
local addon = CreateFrame("Frame")

local TICK_INTERVAL = 0.1
local BUFF_WARNING_SECONDS = 5
local GLOW_THRESHOLD_SECONDS = 10
local TEST_MODE_SECONDS = 20
local READY_FLASH_SECONDS = 1.5
local FALLBACK_ICON = 134400
local ICON_INSET = 1
local COOLDOWN_SWIPE_ALPHA = 0.45

local defaults = {
  locked = false,
  scale = 1.0,
  glowColor = { r = 0.2, g = 0.8, b = 1.0 },
  position = { x = 0, y = -180 },
  potionItemID = 241289,
  auraSpellID = 0,
  alerts = {
    buffWarn = true,
    cooldownReady = true,
  },
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

local db
local settingsPanel
local settingsCategoryID

local ui = {}
local state = {
  buffActive = false,
  buffRemaining = 0,
  buffExpiration = 0,
  buffDuration = 0,
  buffStart = 0,
  cooldownActive = false,
  cooldownRemaining = 0,
  cooldownStart = 0,
  cooldownDuration = 0,
  buffWarned = false,
  readyAnnounced = false,
  readyFlashUntil = 0,
  testModeUntil = 0,
  potionSpellID = nil,
  potionName = nil,
  potionIcon = nil,
  resolvedAuraSpellID = nil,
  nextFallbackScanAt = 0,
}

local SOUND_BUFF_WARNING = SOUNDKIT and (SOUNDKIT.RAID_WARNING or SOUNDKIT.READY_CHECK)
local SOUND_COOLDOWN_READY = SOUNDKIT and (SOUNDKIT.READY_CHECK or SOUNDKIT.UI_PROFESSION_COOLDOWN_END)

local function SafePlaySound(soundKit)
  if soundKit then
    PlaySound(soundKit, "Master")
  end
end

local function DeepCopyDefaults(src, dest)
  for key, value in pairs(src) do
    if type(value) == "table" then
      if type(dest[key]) ~= "table" then
        dest[key] = {}
      end
      DeepCopyDefaults(value, dest[key])
    elseif dest[key] == nil then
      dest[key] = value
    end
  end
end

local function Print(msg)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff5ad4ff%s|r: %s", ADDON_NAME, msg))
  else
    print(ADDON_NAME .. ": " .. tostring(msg))
  end
end

local function IsTestModeActive()
  return state.testModeUntil > GetTime()
end

local function FormatTimer(seconds)
  if seconds <= 0 then
    return "0"
  end
  if seconds >= 60 then
    local minutes = math.floor(seconds / 60)
    local rem = math.floor(seconds % 60)
    return string.format("%d:%02d", minutes, rem)
  end
  if seconds >= 10 then
    return tostring(math.floor(seconds + 0.5))
  end
  return string.format("%.1f", seconds)
end

local function RefreshPotionData()
  local itemID = db.potionItemID
  local spellName, spellID = C_Item.GetItemSpell(itemID)
  state.potionSpellID = spellID
  state.potionName = spellName
  state.potionIcon = C_Item.GetItemIconByID(itemID) or select(10, GetItemInfo(itemID)) or FALLBACK_ICON
  if ui.icon then
    ui.icon:SetTexture(state.potionIcon)
  end
end

local function IsSecretValue(value)
  return type(issecretvalue) == "function" and issecretvalue(value)
end

local function SafeNumber(value)
  if type(value) ~= "number" or IsSecretValue(value) then
    return nil
  end
  return value
end

local function CanAccessTable(value)
  if type(value) ~= "table" then
    return false
  end
  if type(canaccesstable) == "function" then
    local ok, result = pcall(canaccesstable, value)
    return ok and result
  end
  return true
end

local function TryGetAuraBySpellID(spellID)
  if type(spellID) ~= "number" or spellID == 0 or IsSecretValue(spellID) then
    return nil
  end
  if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
    return C_UnitAuras.GetPlayerAuraBySpellID(spellID)
  end
  return nil
end

local function ScanHelpfulAurasFallback()
  if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
    return nil
  end

  -- Never read/compare aura.sourceUnit here: on modern clients it can be a
  -- protected secret value and trigger taint errors in comparisons.
  local bestAura
  local index = 1
  while true do
    local aura = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL|PLAYER")
    if not aura then
      break
    end

    if CanAccessTable(aura) then
      local duration = SafeNumber(aura.duration)
      local expirationTime = SafeNumber(aura.expirationTime)
      local hasDuration = duration and duration > 0 and expirationTime
      if hasDuration then
        local icon = SafeNumber(aura.icon)
        local auraSpellID = SafeNumber(aura.spellId)
        local iconMatch = state.potionIcon and icon and icon == state.potionIcon
        local spellMatch = state.potionSpellID and auraSpellID and auraSpellID == state.potionSpellID
        local durationMatch = duration >= 15 and duration <= 60
        if durationMatch and (iconMatch or spellMatch) then
          local bestExpiration = bestAura and SafeNumber(bestAura.expirationTime) or 0
          if (not bestAura) or (expirationTime > bestExpiration) then
            bestAura = aura
          end
        end
      end
    end

    index = index + 1
  end

  if bestAura then
    local resolved = SafeNumber(bestAura.spellId)
    if resolved and resolved > 0 then
      state.resolvedAuraSpellID = resolved
    end
  end

  return bestAura
end

local function GetBuffState()
  local now = GetTime()
  local aura = TryGetAuraBySpellID(db.auraSpellID ~= 0 and db.auraSpellID or state.potionSpellID)
  if not aura and state.resolvedAuraSpellID then
    aura = TryGetAuraBySpellID(state.resolvedAuraSpellID)
  end
  if not aura and now >= state.nextFallbackScanAt then
    aura = ScanHelpfulAurasFallback()
    state.nextFallbackScanAt = now + 0.5
  end
  if aura and not CanAccessTable(aura) then
    aura = nil
  end

  local expirationTime = aura and SafeNumber(aura.expirationTime) or nil
  local duration = aura and (SafeNumber(aura.duration) or 0) or 0
  if aura and expirationTime and expirationTime > 0 then
    local remaining = expirationTime - GetTime()
    if remaining > 0 then
      local start = expirationTime - duration
      return true, remaining, expirationTime, duration, start
    end
  end

  return false, 0, 0, 0, 0
end

local function GetCooldownState()
  local itemID = db.potionItemID
  local startTime, duration, enabled

  if C_Item and C_Item.GetItemCooldown then
    startTime, duration, enabled = C_Item.GetItemCooldown(itemID)
  else
    startTime, duration, enabled = GetItemCooldown(itemID)
  end

  startTime = startTime or 0
  duration = duration or 0
  if not enabled or enabled == 0 or startTime <= 0 or duration <= 0 then
    return false, 0, 0, 0
  end

  local remaining = (startTime + duration) - GetTime()
  if remaining <= 0 then
    return false, 0, 0, 0
  end

  return true, remaining, startTime, duration
end

local function IsDelveContent()
  if C_DelvesUI and type(C_DelvesUI.HasActiveDelve) == "function" then
    local ok, result = pcall(C_DelvesUI.HasActiveDelve)
    if ok and result ~= nil then
      return result
    end
  end
  if C_Delves and type(C_Delves.IsInDelve) == "function" then
    local ok, result = pcall(C_Delves.IsInDelve)
    if ok and result ~= nil then
      return result
    end
  end
  return false
end

local function GetContentKey()
  local inInstance, instanceType = IsInInstance()
  if not inInstance then
    return "world"
  end
  if instanceType == "party" then
    return "dungeon"
  end
  if instanceType == "raid" then
    return "raid"
  end
  if instanceType == "arena" or instanceType == "pvp" then
    return "pvp"
  end
  if instanceType == "scenario" then
    if IsDelveContent() then
      return "delve"
    end
    return "world"
  end
  if IsDelveContent() then
    return "delve"
  end
  return "world"
end

local function ShouldShowByFilters()
  local inCombat = InCombatLockdown()
  if inCombat and not db.visibility.inCombat then
    return false
  end
  if (not inCombat) and not db.visibility.outOfCombat then
    return false
  end

  local contentKey = GetContentKey()
  if db.visibility[contentKey] == false then
    return false
  end
  return true
end

local function ApplyFrameLock()
  if not ui.frame then
    return
  end
  local unlocked = not db.locked
  ui.frame:EnableMouse(unlocked)
  ui.unlockFrame:SetShown(unlocked)
end

local function ClampScale(value)
  local n = tonumber(value) or 1
  if n < 0.5 then
    return 0.5
  end
  if n > 2.0 then
    return 2.0
  end
  return n
end

local function ClampUnit(value, fallback)
  local n = tonumber(value)
  if not n then
    return fallback or 0
  end
  if n < 0 then
    return 0
  end
  if n > 1 then
    return 1
  end
  return n
end

local function ApplyFrameScale()
  if not ui.frame then
    return
  end
  db.scale = ClampScale(db.scale)
  ui.frame:SetScale(db.scale)
end

local function ApplyGlowColor()
  if not db.glowColor then
    db.glowColor = { r = 0.2, g = 0.8, b = 1.0 }
  end
  db.glowColor.r = ClampUnit(db.glowColor.r, 0.2)
  db.glowColor.g = ClampUnit(db.glowColor.g, 0.8)
  db.glowColor.b = ClampUnit(db.glowColor.b, 1.0)

  if not ui.glowEdges then
    return
  end

  local r, g, b = db.glowColor.r, db.glowColor.g, db.glowColor.b
  for _, tex in ipairs(ui.glowEdges) do
    tex:SetColorTexture(r, g, b, 1.0)
  end
  local cr = ClampUnit(r + 0.15, 1.0)
  local cg = ClampUnit(g + 0.15, 1.0)
  local cb = ClampUnit(b + 0.15, 1.0)
  for _, tex in ipairs(ui.glowCorners) do
    tex:SetColorTexture(cr, cg, cb, 1.0)
  end
end

local function SavePosition()
  local _, _, _, x, y = ui.frame:GetPoint(1)
  db.position.x = x
  db.position.y = y
end

local function TriggerReadyFlash()
  state.readyFlashUntil = GetTime() + READY_FLASH_SECONDS
end

local function UpdatePixelGlow(now, testMode)
  if not ui.glowFrame then
    return
  end

  local glowActive = (not testMode) and (not state.buffActive) and state.cooldownActive and state.cooldownRemaining <= GLOW_THRESHOLD_SECONDS
  if not glowActive then
    ui.glowFrame:Hide()
    return
  end

  ui.glowFrame:Show()
  local pulse = 0.4 + (0.6 * (0.5 + 0.5 * math.sin(now * 10)))
  ui.glowFrame:SetAlpha(pulse)
end

local function Render()
  if not ui.frame or not ui.cooldown or not ui.timerText then
    return
  end

  local now = GetTime()
  local testMode = IsTestModeActive()
  local moveMode = not db.locked
  local show = moveMode or testMode or ShouldShowByFilters()

  if not show then
    ui.frame:Hide()
    return
  end

  ui.frame:Show()
  local text

  if moveMode and (not testMode) and (not state.buffActive) and (not state.cooldownActive) then
    text = "MOVE"
    if CooldownFrame_Clear then
      CooldownFrame_Clear(ui.cooldown)
    else
      ui.cooldown:SetCooldown(0, 0)
    end
  elseif testMode then
    local rem = state.testModeUntil - now
    text = FormatTimer(rem)
    ui.cooldown:SetCooldown(now - (TEST_MODE_SECONDS - rem), TEST_MODE_SECONDS)
  elseif state.buffActive then
    text = FormatTimer(state.buffRemaining)
    ui.cooldown:SetCooldown(state.buffStart, math.max(0.001, state.buffDuration))
  elseif state.cooldownActive then
    text = FormatTimer(state.cooldownRemaining)
    ui.cooldown:SetCooldown(state.cooldownStart, state.cooldownDuration)
  else
    text = ""
    if CooldownFrame_Clear then
      CooldownFrame_Clear(ui.cooldown)
    else
      ui.cooldown:SetCooldown(0, 0)
    end
  end

  ui.timerText:SetText(text)
  if ui.statusText then
    if testMode or state.cooldownActive then
      ui.statusText:SetText("CD")
      ui.statusText:SetTextColor(1.0, 0.82, 0.35)
    else
      ui.statusText:SetText("READY")
      ui.statusText:SetTextColor(0.45, 1.0, 0.55)
    end
  end
  UpdatePixelGlow(now, testMode)
  if now < state.readyFlashUntil then
    ui.flashText:Show()
    ui.flashText:SetText("READY")
  else
    ui.flashText:Hide()
  end
end

local function RefreshState()
  if not state.potionSpellID or not state.potionName then
    RefreshPotionData()
  end

  local prevBuffActive = state.buffActive
  local prevCooldownActive = state.cooldownActive
  local prevCooldownRemaining = state.cooldownRemaining

  state.buffActive, state.buffRemaining, state.buffExpiration, state.buffDuration, state.buffStart = GetBuffState()
  state.cooldownActive, state.cooldownRemaining, state.cooldownStart, state.cooldownDuration = GetCooldownState()

  if state.buffActive and not prevBuffActive then
    state.buffWarned = false
    state.readyAnnounced = false
  end

  if state.buffActive then
    if state.buffRemaining <= BUFF_WARNING_SECONDS and not state.buffWarned then
      if db.alerts.buffWarn then
        SafePlaySound(SOUND_BUFF_WARNING)
      end
      state.buffWarned = true
    end
  else
    state.buffWarned = false
  end

  if state.cooldownActive and not prevCooldownActive then
    state.readyAnnounced = false
  end

  if (not state.cooldownActive) and prevCooldownRemaining > 0 and not state.readyAnnounced then
    state.readyAnnounced = true
    TriggerReadyFlash()
    if db.alerts.cooldownReady then
      SafePlaySound(SOUND_COOLDOWN_READY)
    end
  end
end

local function OnUpdate(_, elapsed)
  ui.elapsed = ui.elapsed + elapsed
  if ui.elapsed < TICK_INTERVAL then
    return
  end
  ui.elapsed = 0
  RefreshState()
  Render()
end

local function CreateTrackerFrame()
  local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
  local frame = CreateFrame("Frame", "RecklessTrackerFrame", UIParent, backdropTemplate)
  frame:SetSize(52, 52)
  frame:SetPoint("CENTER", UIParent, "CENTER", db.position.x, db.position.y)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if db.locked then
      return
    end
    self:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition()
  end)

  local panel = CreateFrame("Frame", nil, frame, backdropTemplate)
  panel:SetAllPoints(frame)
  panel:SetFrameLevel(frame:GetFrameLevel())
  if panel.SetBackdrop then
    panel:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = 1,
    })
    panel:SetBackdropColor(0, 0, 0, 0)
    panel:SetBackdropBorderColor(0.12, 0.12, 0.12, 0.95)
  else
    local panelBG = panel:CreateTexture(nil, "BACKGROUND")
    panelBG:SetAllPoints(panel)
    panelBG:SetColorTexture(0, 0, 0, 0)
  end

  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", panel, "TOPLEFT", ICON_INSET, -ICON_INSET)
  icon:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
  icon:SetTexture(state.potionIcon or FALLBACK_ICON)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  icon:SetDesaturated(false)
  icon:SetVertexColor(1, 1, 1, 1)

  local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
  cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
  cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
  cooldown:SetFrameLevel(panel:GetFrameLevel() + 2)
  if cooldown.SetDrawEdge then
    cooldown:SetDrawEdge(true)
  end
  if cooldown.SetDrawBling then
    cooldown:SetDrawBling(false)
  end
  if cooldown.SetDrawSwipe then
    cooldown:SetDrawSwipe(true)
  end
  if cooldown.SetSwipeColor then
    cooldown:SetSwipeColor(0, 0, 0, COOLDOWN_SWIPE_ALPHA)
  end
  if cooldown.SetHideCountdownNumbers then
    cooldown:SetHideCountdownNumbers(true)
  end

  local textLayer = CreateFrame("Frame", nil, frame)
  textLayer:SetAllPoints(icon)
  textLayer:SetFrameStrata(frame:GetFrameStrata())
  textLayer:SetFrameLevel(cooldown:GetFrameLevel() + 8)

  local unlockFrame = CreateFrame("Frame", nil, frame)
  unlockFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
  unlockFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
  unlockFrame:Hide()

  local unlockTop = unlockFrame:CreateTexture(nil, "OVERLAY")
  unlockTop:SetColorTexture(0.85, 0.75, 0.25, 1)
  unlockTop:SetPoint("TOPLEFT", unlockFrame, "TOPLEFT", 0, 0)
  unlockTop:SetPoint("TOPRIGHT", unlockFrame, "TOPRIGHT", 0, 0)
  unlockTop:SetHeight(1)

  local unlockBottom = unlockFrame:CreateTexture(nil, "OVERLAY")
  unlockBottom:SetColorTexture(0.85, 0.75, 0.25, 1)
  unlockBottom:SetPoint("BOTTOMLEFT", unlockFrame, "BOTTOMLEFT", 0, 0)
  unlockBottom:SetPoint("BOTTOMRIGHT", unlockFrame, "BOTTOMRIGHT", 0, 0)
  unlockBottom:SetHeight(1)

  local unlockLeft = unlockFrame:CreateTexture(nil, "OVERLAY")
  unlockLeft:SetColorTexture(0.85, 0.75, 0.25, 1)
  unlockLeft:SetPoint("TOPLEFT", unlockFrame, "TOPLEFT", 0, 0)
  unlockLeft:SetPoint("BOTTOMLEFT", unlockFrame, "BOTTOMLEFT", 0, 0)
  unlockLeft:SetWidth(1)

  local unlockRight = unlockFrame:CreateTexture(nil, "OVERLAY")
  unlockRight:SetColorTexture(0.85, 0.75, 0.25, 1)
  unlockRight:SetPoint("TOPRIGHT", unlockFrame, "TOPRIGHT", 0, 0)
  unlockRight:SetPoint("BOTTOMRIGHT", unlockFrame, "BOTTOMRIGHT", 0, 0)
  unlockRight:SetWidth(1)

  local glowFrame = CreateFrame("Frame", nil, frame)
  glowFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 3)
  glowFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3)
  glowFrame:Hide()

  local glowTop = glowFrame:CreateTexture(nil, "OVERLAY")
  glowTop:SetPoint("TOPLEFT", glowFrame, "TOPLEFT", 0, 0)
  glowTop:SetPoint("TOPRIGHT", glowFrame, "TOPRIGHT", 0, 0)
  glowTop:SetHeight(2)

  local glowBottom = glowFrame:CreateTexture(nil, "OVERLAY")
  glowBottom:SetPoint("BOTTOMLEFT", glowFrame, "BOTTOMLEFT", 0, 0)
  glowBottom:SetPoint("BOTTOMRIGHT", glowFrame, "BOTTOMRIGHT", 0, 0)
  glowBottom:SetHeight(2)

  local glowLeft = glowFrame:CreateTexture(nil, "OVERLAY")
  glowLeft:SetPoint("TOPLEFT", glowFrame, "TOPLEFT", 0, 0)
  glowLeft:SetPoint("BOTTOMLEFT", glowFrame, "BOTTOMLEFT", 0, 0)
  glowLeft:SetWidth(2)

  local glowRight = glowFrame:CreateTexture(nil, "OVERLAY")
  glowRight:SetPoint("TOPRIGHT", glowFrame, "TOPRIGHT", 0, 0)
  glowRight:SetPoint("BOTTOMRIGHT", glowFrame, "BOTTOMRIGHT", 0, 0)
  glowRight:SetWidth(2)

  local cornerSize = 3
  local corners = {}
  for i = 1, 4 do
    corners[i] = glowFrame:CreateTexture(nil, "OVERLAY")
    corners[i]:SetSize(cornerSize, cornerSize)
  end
  corners[1]:SetPoint("TOPLEFT", glowFrame, "TOPLEFT", -1, 1)
  corners[2]:SetPoint("TOPRIGHT", glowFrame, "TOPRIGHT", 1, 1)
  corners[3]:SetPoint("BOTTOMLEFT", glowFrame, "BOTTOMLEFT", -1, -1)
  corners[4]:SetPoint("BOTTOMRIGHT", glowFrame, "BOTTOMRIGHT", 1, -1)

  local timerText = textLayer:CreateFontString(nil, "OVERLAY")
  timerText:SetPoint("CENTER", textLayer, "CENTER", 0, 0)
  timerText:SetTextColor(1, 0.97, 0.85)
  timerText:SetFont(STANDARD_TEXT_FONT, 20, "THICKOUTLINE")
  timerText:SetShadowOffset(1, -1)
  timerText:SetShadowColor(0, 0, 0, 1)

  local statusText = textLayer:CreateFontString(nil, "OVERLAY")
  statusText:SetPoint("BOTTOM", frame, "TOP", 0, 1)
  statusText:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
  statusText:SetText("READY")
  statusText:SetTextColor(0.45, 1.0, 0.55)
  statusText:SetShadowOffset(1, -1)
  statusText:SetShadowColor(0, 0, 0, 1)

  local flashText = frame:CreateFontString(nil, "OVERLAY")
  flashText:SetPoint("TOP", frame, "BOTTOM", 0, -2)
  flashText:SetTextColor(0.9, 0.95, 1)
  flashText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
  flashText:SetShadowOffset(0, 0)
  flashText:SetShadowColor(0, 0, 0, 1)
  flashText:Hide()

  ui.frame = frame
  ui.panel = panel
  ui.icon = icon
  ui.cooldown = cooldown
  ui.unlockFrame = unlockFrame
  ui.glowFrame = glowFrame
  ui.glowEdges = { glowTop, glowBottom, glowLeft, glowRight }
  ui.glowCorners = corners
  ui.timerText = timerText
  ui.statusText = statusText
  ui.flashText = flashText
  ui.elapsed = 0

  ApplyFrameLock()
  ApplyFrameScale()
  ApplyGlowColor()
  frame:SetScript("OnUpdate", OnUpdate)
end

local function CreateCheckbox(parent, label, x, y, getter, setter)
  local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
  check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  check:SetChecked(getter())
  if check.Text then
    check.Text:SetText(label)
  else
    local name = check:GetName()
    if name and _G[name .. "Text"] then
      _G[name .. "Text"]:SetText(label)
    end
  end
  check:SetScript("OnClick", function(self)
    setter(self:GetChecked())
    RefreshState()
    Render()
  end)
  return check
end

local function CreateSlider(parent, name, x, y, width, minValue, maxValue, step, label, lowText, highText, getValue, onValueChanged)
  local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  slider:SetMinMaxValues(minValue, maxValue)
  slider:SetValueStep(step)
  slider:SetObeyStepOnDrag(true)
  slider:SetWidth(width)
  slider:SetValue(getValue())
  _G[slider:GetName() .. "Text"]:SetText(label)
  _G[slider:GetName() .. "Low"]:SetText(lowText)
  _G[slider:GetName() .. "High"]:SetText(highText)
  slider:SetScript("OnValueChanged", function(self, value)
    onValueChanged(value)
  end)
  return slider
end

local function OpenSettings()
  if Settings and Settings.OpenToCategory and settingsCategoryID then
    Settings.OpenToCategory(settingsCategoryID)
    return
  end
  if InterfaceOptionsFrame_OpenToCategory and settingsPanel then
    InterfaceOptionsFrame_OpenToCategory(settingsPanel)
    InterfaceOptionsFrame_OpenToCategory(settingsPanel)
  end
end

local function RegisterSettingsPanel()
  local panel = CreateFrame("Frame")
  panel.name = "RecklessTracker"

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("RecklessTracker")

  local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  subtitle:SetText("Potion of Recklessness tracker options")

  local controls = {
    { "Show In Combat", -50, function() return db.visibility.inCombat end, function(v) db.visibility.inCombat = v end },
    { "Show Out of Combat", -74, function() return db.visibility.outOfCombat end, function(v) db.visibility.outOfCombat = v end },
    { "Show in Open World", -110, function() return db.visibility.world end, function(v) db.visibility.world = v end },
    { "Show in Dungeons/Mythic+", -134, function() return db.visibility.dungeon end, function(v) db.visibility.dungeon = v end },
    { "Show in Raids", -158, function() return db.visibility.raid end, function(v) db.visibility.raid = v end },
    { "Show in PvP", -182, function() return db.visibility.pvp end, function(v) db.visibility.pvp = v end },
    { "Show in Delves", -206, function() return db.visibility.delve end, function(v) db.visibility.delve = v end },
    { "Buff warning sound", -242, function() return db.alerts.buffWarn end, function(v) db.alerts.buffWarn = v end },
    { "Cooldown ready sound", -266, function() return db.alerts.cooldownReady end, function(v) db.alerts.cooldownReady = v end },
    {
      "Lock frame",
      -302,
      function() return db.locked end,
      function(v)
        db.locked = v
        ApplyFrameLock()
      end,
    },
  }

  local checkboxes = {}
  for _, entry in ipairs(controls) do
    local check = CreateCheckbox(panel, entry[1], 16, entry[2], entry[3], entry[4])
    table.insert(checkboxes, { check = check, getter = entry[3] })
  end

  panel:SetScript("OnShow", function()
    for _, control in ipairs(checkboxes) do
      control.check:SetChecked(control.getter())
    end
    if ui.scaleSlider then
      ui.scaleSlider:SetValue(db.scale)
    end
    if ui.glowRedSlider then
      ui.glowRedSlider:SetValue(db.glowColor.r)
      ui.glowGreenSlider:SetValue(db.glowColor.g)
      ui.glowBlueSlider:SetValue(db.glowColor.b)
    end
  end)

  local slider = CreateSlider(
    panel,
    "RecklessTrackerScaleSlider",
    20,
    -352,
    220,
    0.5,
    2.0,
    0.05,
    "Icon Scale",
    "0.5",
    "2.0",
    function() return db.scale end,
    function(value)
      db.scale = ClampScale(value)
      ApplyFrameScale()
      if ui.scaleValueText then
        ui.scaleValueText:SetText(string.format("%.2f", db.scale))
      end
    end
  )

  local scaleValueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  scaleValueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
  scaleValueText:SetText(string.format("%.2f", db.scale))

  ui.scaleSlider = slider
  ui.scaleValueText = scaleValueText

  local glowLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  glowLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -392)
  glowLabel:SetText("Glow Color (RGB)")

  local redSlider = CreateSlider(
    panel,
    "RecklessTrackerGlowRedSlider",
    20,
    -418,
    220,
    0.0,
    1.0,
    0.01,
    "Glow Red",
    "0.00",
    "1.00",
    function() return db.glowColor.r end,
    function(value)
      db.glowColor.r = ClampUnit(value, db.glowColor.r)
      ApplyGlowColor()
      if ui.glowValueText then
        ui.glowValueText:SetText(string.format("R %.2f  G %.2f  B %.2f", db.glowColor.r, db.glowColor.g, db.glowColor.b))
      end
    end
  )

  local greenSlider = CreateSlider(
    panel,
    "RecklessTrackerGlowGreenSlider",
    20,
    -458,
    220,
    0.0,
    1.0,
    0.01,
    "Glow Green",
    "0.00",
    "1.00",
    function() return db.glowColor.g end,
    function(value)
      db.glowColor.g = ClampUnit(value, db.glowColor.g)
      ApplyGlowColor()
      if ui.glowValueText then
        ui.glowValueText:SetText(string.format("R %.2f  G %.2f  B %.2f", db.glowColor.r, db.glowColor.g, db.glowColor.b))
      end
    end
  )

  local blueSlider = CreateSlider(
    panel,
    "RecklessTrackerGlowBlueSlider",
    20,
    -498,
    220,
    0.0,
    1.0,
    0.01,
    "Glow Blue",
    "0.00",
    "1.00",
    function() return db.glowColor.b end,
    function(value)
      db.glowColor.b = ClampUnit(value, db.glowColor.b)
      ApplyGlowColor()
      if ui.glowValueText then
        ui.glowValueText:SetText(string.format("R %.2f  G %.2f  B %.2f", db.glowColor.r, db.glowColor.g, db.glowColor.b))
      end
    end
  )

  local glowValueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  glowValueText:SetPoint("TOPLEFT", panel, "TOPLEFT", 260, -432)
  glowValueText:SetText(string.format("R %.2f  G %.2f  B %.2f", db.glowColor.r, db.glowColor.g, db.glowColor.b))

  ui.glowRedSlider = redSlider
  ui.glowGreenSlider = greenSlider
  ui.glowBlueSlider = blueSlider
  ui.glowValueText = glowValueText

  settingsPanel = panel
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "RecklessTracker")
    Settings.RegisterAddOnCategory(category)
    settingsCategoryID = category:GetID()
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

local function StartTestMode()
  state.testModeUntil = GetTime() + TEST_MODE_SECONDS
  TriggerReadyFlash()
  Print("Test mode started for 20 seconds.")
end

local function SetPotionItemID(value)
  local newID = tonumber(value)
  if not newID or newID <= 0 then
    Print("Usage: /rt item <itemID>")
    return
  end
  db.potionItemID = math.floor(newID)
  state.potionSpellID = nil
  state.potionName = nil
  state.potionIcon = nil
  state.resolvedAuraSpellID = nil
  state.nextFallbackScanAt = 0
  RefreshPotionData()
  RefreshState()
  Render()
  Print("Potion item ID set to " .. db.potionItemID)
end

local function SetAuraSpellID(value)
  local newID = tonumber(value)
  if not newID then
    Print("Usage: /rt aura <spellID>")
    return
  end
  db.auraSpellID = math.max(0, math.floor(newID))
  state.resolvedAuraSpellID = nil
  state.nextFallbackScanAt = 0
  RefreshState()
  Render()
  if db.auraSpellID == 0 then
    Print("Aura spell override cleared. Using auto-detect.")
  else
    Print("Aura spell ID set to " .. db.auraSpellID)
  end
end

local function SetIconScale(value)
  local n = tonumber(value)
  if not n then
    Print("Usage: /rt size <0.5 - 2.0>")
    return
  end
  db.scale = ClampScale(n)
  ApplyFrameScale()
  if ui.scaleSlider then
    ui.scaleSlider:SetValue(db.scale)
  end
  if ui.scaleValueText then
    ui.scaleValueText:SetText(string.format("%.2f", db.scale))
  end
  Print(string.format("Icon scale set to %.2f", db.scale))
end

local function SetGlowColorFromString(value)
  local r, g, b = string.match(value or "", "^(%-?[%d%.]+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)$")
  if not r or not g or not b then
    Print("Usage: /rt glow <r> <g> <b> (0.0 - 1.0)")
    return
  end

  db.glowColor.r = ClampUnit(r, db.glowColor.r)
  db.glowColor.g = ClampUnit(g, db.glowColor.g)
  db.glowColor.b = ClampUnit(b, db.glowColor.b)
  ApplyGlowColor()
  if ui.glowRedSlider then
    ui.glowRedSlider:SetValue(db.glowColor.r)
    ui.glowGreenSlider:SetValue(db.glowColor.g)
    ui.glowBlueSlider:SetValue(db.glowColor.b)
  end
  if ui.glowValueText then
    ui.glowValueText:SetText(string.format("R %.2f  G %.2f  B %.2f", db.glowColor.r, db.glowColor.g, db.glowColor.b))
  end
  Print(string.format("Glow color set to R %.2f G %.2f B %.2f", db.glowColor.r, db.glowColor.g, db.glowColor.b))
end

local function RegisterSlashCommands()
  SLASH_RECKLESSTRACKER1 = "/rt"
  SlashCmdList.RECKLESSTRACKER = function(msg)
    local input = strtrim((msg or ""))
    local cmd, arg = input:match("^(%S+)%s*(.-)$")
    cmd = cmd and string.lower(cmd) or ""

    if cmd == "" then
      OpenSettings()
      return
    end

    if cmd == "lock" then
      db.locked = not db.locked
      ApplyFrameLock()
      Print(db.locked and "Frame locked." or "Frame unlocked. Drag the icon now.")
      Render()
      return
    end

    if cmd == "unlock" then
      db.locked = false
      ApplyFrameLock()
      Print("Frame unlocked. Drag the icon now.")
      Render()
      return
    end

    if cmd == "test" then
      StartTestMode()
      return
    end

    if cmd == "item" then
      SetPotionItemID(arg)
      return
    end

    if cmd == "aura" then
      SetAuraSpellID(arg)
      return
    end

    if cmd == "status" then
      Print(string.format(
        "itemID=%d auraSpellID=%d autoSpellID=%s scale=%.2f glow=%.2f,%.2f,%.2f",
        db.potionItemID,
        db.auraSpellID,
        tostring(state.potionSpellID),
        db.scale,
        db.glowColor.r,
        db.glowColor.g,
        db.glowColor.b
      ))
      return
    end

    if cmd == "size" or cmd == "scale" then
      SetIconScale(arg)
      return
    end

    if cmd == "glow" then
      SetGlowColorFromString(arg)
      return
    end

    Print("Commands: /rt, /rt lock, /rt unlock, /rt size <0.5-2.0>, /rt glow <r g b>, /rt test, /rt item <id>, /rt aura <spellId>, /rt status")
  end
end

local function InitializeDatabase()
  if type(RecklessTrackerDB) ~= "table" then
    RecklessTrackerDB = {}
  end
  DeepCopyDefaults(defaults, RecklessTrackerDB)
  db = RecklessTrackerDB
end

local function Initialize()
  InitializeDatabase()
  RegisterSlashCommands()
  RefreshPotionData()
  local frameOk, frameErr = pcall(CreateTrackerFrame)
  if not frameOk then
    Print("Tracker frame failed to initialize: " .. tostring(frameErr))
  end

  local settingsOk, settingsErr = pcall(RegisterSettingsPanel)
  if not settingsOk then
    Print("Settings panel failed to initialize: " .. tostring(settingsErr))
  end

  RefreshState()
  Render()

  addon:RegisterEvent("UNIT_AURA")
  addon:RegisterEvent("BAG_UPDATE_COOLDOWN")
  addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
  addon:RegisterEvent("PLAYER_REGEN_DISABLED")
  addon:RegisterEvent("PLAYER_REGEN_ENABLED")
  addon:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  addon:RegisterEvent("PLAYER_ENTERING_WORLD")

  Print("Loaded. Use /rt for settings.")
end

addon:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    Initialize()
    return
  end

  if event == "UNIT_AURA" then
    local unitToken = ...
    if unitToken ~= "player" then
      return
    end
  end

  RefreshState()
  Render()
end)

addon:RegisterEvent("PLAYER_LOGIN")
