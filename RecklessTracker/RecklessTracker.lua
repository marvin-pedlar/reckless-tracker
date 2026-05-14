local ADDON_NAME = ...
local addon = CreateFrame("Frame")

local TICK_INTERVAL = 0.1
local BUFF_WARNING_SECONDS = 5
local GLOW_THRESHOLD_SECONDS = 10
local TEST_MODE_SECONDS = 20
local READY_FLASH_SECONDS = 1.5
local FALLBACK_ICON = 134400
local BOOTSTRAP_ICON_INSET = 1
local BOOTSTRAP_COOLDOWN_SWIPE_ALPHA = 0.45
local STYLE_VERSION = 1

local function NewDefaultStyle()
  return {
    frame = {
      backgroundColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.0 },
      borderColor = { r = 0.12, g = 0.12, b = 0.12, a = 0.95 },
      borderThickness = 1,
    },
    icon = {
      inset = 1,
      texCoordInset = 0.08,
      alpha = 1.0,
      desaturated = false,
    },
    cooldown = {
      drawEdge = true,
      drawSwipe = true,
      swipeColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.45 },
    },
    text = {
      timer = {
        color = { r = 1.0, g = 0.97, b = 0.85, a = 1.0 },
        size = 20,
        outline = "THICKOUTLINE",
        shadowColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
        shadowOffsetX = 1,
        shadowOffsetY = -1,
      },
      status = {
        readyColor = { r = 0.45, g = 1.0, b = 0.55, a = 1.0 },
        cdColor = { r = 1.0, g = 0.82, b = 0.35, a = 1.0 },
        size = 10,
        outline = "OUTLINE",
        shadowColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
        shadowOffsetX = 1,
        shadowOffsetY = -1,
      },
      flash = {
        color = { r = 0.9, g = 0.95, b = 1.0, a = 1.0 },
        size = 11,
        outline = "OUTLINE",
        shadowColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
        shadowOffsetX = 0,
        shadowOffsetY = 0,
      },
    },
    glow = {
      color = { r = 0.2, g = 0.8, b = 1.0, a = 1.0 },
      thresholdSeconds = 10,
      pulseMin = 0.4,
      pulseMax = 1.0,
      edgeThickness = 2,
      cornerSize = 3,
      cornerBoost = 0.15,
      frameOutset = 3,
    },
    unlock = {
      color = { r = 0.85, g = 0.75, b = 0.25, a = 1.0 },
      thickness = 1,
      frameOutset = 2,
      statusOffsetY = 1,
    },
  }
end

local function NewStylePresets()
  return {
    ["Classic"] = NewDefaultStyle(),
    ["ElvUI Thin"] = {
      frame = {
        backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.06 },
        borderColor = { r = 0.12, g = 0.12, b = 0.12, a = 0.95 },
        borderThickness = 1,
      },
      icon = {
        inset = 1,
        texCoordInset = 0.08,
        alpha = 1.0,
        desaturated = false,
      },
      cooldown = {
        drawEdge = true,
        drawSwipe = true,
        swipeColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.45 },
      },
      text = {
        timer = {
          color = { r = 1.0, g = 0.97, b = 0.85, a = 1.0 },
          size = 20,
          outline = "THICKOUTLINE",
          shadowColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
          shadowOffsetX = 1,
          shadowOffsetY = -1,
        },
        status = {
          readyColor = { r = 0.45, g = 1.0, b = 0.55, a = 1.0 },
          cdColor = { r = 1.0, g = 0.82, b = 0.35, a = 1.0 },
          size = 10,
          outline = "OUTLINE",
          shadowColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
          shadowOffsetX = 1,
          shadowOffsetY = -1,
        },
        flash = {
          color = { r = 0.9, g = 0.95, b = 1.0, a = 1.0 },
          size = 11,
          outline = "OUTLINE",
          shadowColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
          shadowOffsetX = 0,
          shadowOffsetY = 0,
        },
      },
      glow = {
        color = { r = 0.2, g = 0.8, b = 1.0, a = 1.0 },
        thresholdSeconds = 10,
        pulseMin = 0.35,
        pulseMax = 1.0,
        edgeThickness = 2,
        cornerSize = 3,
        cornerBoost = 0.15,
        frameOutset = 3,
      },
      unlock = {
        color = { r = 0.85, g = 0.75, b = 0.25, a = 1.0 },
        thickness = 1,
        frameOutset = 2,
        statusOffsetY = 1,
      },
    },
    ["High Contrast"] = {
      frame = {
        backgroundColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.25 },
        borderColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
        borderThickness = 2,
      },
      icon = {
        inset = 1,
        texCoordInset = 0.08,
        alpha = 1.0,
        desaturated = false,
      },
      cooldown = {
        drawEdge = true,
        drawSwipe = true,
        swipeColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.65 },
      },
      text = {
        timer = {
          color = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
          size = 22,
          outline = "THICKOUTLINE",
          shadowColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
          shadowOffsetX = 1,
          shadowOffsetY = -1,
        },
        status = {
          readyColor = { r = 0.3, g = 1.0, b = 0.3, a = 1.0 },
          cdColor = { r = 1.0, g = 0.9, b = 0.25, a = 1.0 },
          size = 11,
          outline = "THICKOUTLINE",
          shadowColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
          shadowOffsetX = 1,
          shadowOffsetY = -1,
        },
        flash = {
          color = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
          size = 12,
          outline = "THICKOUTLINE",
          shadowColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
          shadowOffsetX = 0,
          shadowOffsetY = 0,
        },
      },
      glow = {
        color = { r = 0.2, g = 0.9, b = 1.0, a = 1.0 },
        thresholdSeconds = 10,
        pulseMin = 0.5,
        pulseMax = 1.0,
        edgeThickness = 2,
        cornerSize = 3,
        cornerBoost = 0.2,
        frameOutset = 3,
      },
      unlock = {
        color = { r = 1.0, g = 0.88, b = 0.3, a = 1.0 },
        thickness = 1,
        frameOutset = 2,
        statusOffsetY = 1,
      },
    },
  }
end

local defaults = {
  locked = false,
  scale = 1.0,
  glowColor = { r = 0.2, g = 0.8, b = 1.0 },
  styleVersion = STYLE_VERSION,
  activeStylePreset = "ElvUI Thin",
  styleProfiles = {},
  style = NewDefaultStyle(),
  position = { x = 0, y = -180 },
  potionItemID = 241289,
  auraSpellID = 0,
  alerts = {
    buffWarn = true,
    cooldownReady = true,
    useTts = false,
    ttsVoiceID = nil,
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
local styleSettingsPanel
local settingsCategoryID
local styleSettingsCategoryID
local STYLE_PRESETS = NewStylePresets()
local styleControlRefreshers = {}
local anonymousSliderCount = 0

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
  potionAvailable = false,
  resolvedAuraSpellID = nil,
  nextFallbackScanAt = 0,
}

local SOUND_BUFF_WARNING = SOUNDKIT and (SOUNDKIT.RAID_WARNING or SOUNDKIT.READY_CHECK)
local SOUND_COOLDOWN_READY = SOUNDKIT and (SOUNDKIT.READY_CHECK or SOUNDKIT.UI_PROFESSION_COOLDOWN_END)
local ClampUnit

local function SafePlaySound(soundKit)
  if soundKit then
    PlaySound(soundKit, "Master")
  end
end

local function SafeTtsNumber(getter, fallback)
  local ok, value = pcall(getter)
  if ok and type(value) == "number" then
    return value
  end
  return fallback
end

local STANDARD_TTS_VOICE_TYPE = Enum and Enum.TtsVoiceType and Enum.TtsVoiceType.Standard or 0

local function GetDefaultTtsVoiceID()
  if C_TTSSettings and type(C_TTSSettings.GetVoiceOptionID) == "function" then
    local ok, value = pcall(function()
      return C_TTSSettings.GetVoiceOptionID(STANDARD_TTS_VOICE_TYPE)
    end)
    if ok and type(value) == "number" then
      return value
    end
  end
  return 0
end

local function GetSelectableTtsVoices()
  local options = {
    { id = nil, label = "WoW default" },
  }

  if not (C_VoiceChat and type(C_VoiceChat.GetTtsVoices) == "function") then
    return options
  end

  local ok, voices = pcall(C_VoiceChat.GetTtsVoices)
  if not ok or type(voices) ~= "table" then
    return options
  end

  table.sort(voices, function(left, right)
    local leftName = type(left and left.name) == "string" and left.name or ""
    local rightName = type(right and right.name) == "string" and right.name or ""
    if leftName == rightName then
      return tonumber(left and left.voiceID or 0) < tonumber(right and right.voiceID or 0)
    end
    return leftName < rightName
  end)

  for _, voice in ipairs(voices) do
    if type(voice.voiceID) == "number" then
      local label = voice.name
      if type(label) ~= "string" or label == "" then
        label = "Voice " .. voice.voiceID
      end
      options[#options + 1] = {
        id = voice.voiceID,
        label = label,
      }
    end
  end

  return options
end

local function ResolveTtsVoiceID()
  if type(db.alerts.ttsVoiceID) ~= "number" then
    return GetDefaultTtsVoiceID()
  end

  for _, voice in ipairs(GetSelectableTtsVoices()) do
    if voice.id == db.alerts.ttsVoiceID then
      return db.alerts.ttsVoiceID
    end
  end

  return GetDefaultTtsVoiceID()
end

local function GetTtsVoiceID()
  local voiceID = ResolveTtsVoiceID()
  if type(voiceID) == "number" then
    return voiceID
  end
  return 0
end

local function GetTtsSpeechRate()
  if C_TTSSettings and type(C_TTSSettings.GetSpeechRate) == "function" then
    return SafeTtsNumber(C_TTSSettings.GetSpeechRate, 0)
  end
  return 0
end

local function GetTtsSpeechVolume()
  if C_TTSSettings and type(C_TTSSettings.GetSpeechVolume) == "function" then
    return SafeTtsNumber(C_TTSSettings.GetSpeechVolume, 100)
  end
  return 100
end

local function SpeakTtsAlert(text)
  if not (C_VoiceChat and type(C_VoiceChat.SpeakText) == "function") then
    return false
  end

  local voiceID = GetTtsVoiceID()
  local rate = GetTtsSpeechRate()
  local volume = GetTtsSpeechVolume()
  local ok = pcall(C_VoiceChat.SpeakText, voiceID, text, rate, volume, true)
  return ok
end

local function AlertPotionReady()
  if db.alerts.useTts and SpeakTtsAlert("potion ready") then
    return
  end
  if db.alerts.cooldownReady then
    SafePlaySound(SOUND_COOLDOWN_READY)
  end
end

local function AlertPotionEnded()
  if db.alerts.useTts then
    SpeakTtsAlert("potion ended")
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

local function DeepCopyTable(value)
  if type(value) ~= "table" then
    return value
  end
  local copied = {}
  for key, subValue in pairs(value) do
    copied[key] = DeepCopyTable(subValue)
  end
  return copied
end

local function ClampRange(value, minValue, maxValue, fallback)
  local n = tonumber(value)
  if not n then
    n = fallback or minValue
  end
  if n < minValue then
    return minValue
  end
  if n > maxValue then
    return maxValue
  end
  return n
end

local function NormalizeColor(color, fallback)
  local safeFallback = fallback or { r = 1, g = 1, b = 1, a = 1 }
  if type(color) ~= "table" then
    color = {}
  end
  color.r = ClampUnit(color.r, safeFallback.r or 1)
  color.g = ClampUnit(color.g, safeFallback.g or 1)
  color.b = ClampUnit(color.b, safeFallback.b or 1)
  color.a = ClampUnit(color.a, safeFallback.a or 1)
  return color
end

local function NormalizeStyle()
  if type(db.style) ~= "table" then
    db.style = {}
  end
  DeepCopyDefaults(NewDefaultStyle(), db.style)

  db.style.frame.backgroundColor = NormalizeColor(db.style.frame.backgroundColor, { r = 0, g = 0, b = 0, a = 0 })
  db.style.frame.borderColor = NormalizeColor(db.style.frame.borderColor, { r = 0.12, g = 0.12, b = 0.12, a = 0.95 })
  db.style.frame.borderThickness = ClampRange(db.style.frame.borderThickness, 1, 4, 1)

  db.style.icon.inset = ClampRange(db.style.icon.inset, 0, 8, 1)
  db.style.icon.texCoordInset = ClampRange(db.style.icon.texCoordInset, 0, 0.25, 0.08)
  db.style.icon.alpha = ClampUnit(db.style.icon.alpha, 1.0)
  db.style.icon.desaturated = db.style.icon.desaturated and true or false

  db.style.cooldown.drawEdge = db.style.cooldown.drawEdge ~= false
  db.style.cooldown.drawSwipe = db.style.cooldown.drawSwipe ~= false
  db.style.cooldown.swipeColor = NormalizeColor(db.style.cooldown.swipeColor, { r = 0, g = 0, b = 0, a = 0.45 })

  db.style.text.timer.color = NormalizeColor(db.style.text.timer.color, { r = 1, g = 0.97, b = 0.85, a = 1 })
  db.style.text.timer.shadowColor = NormalizeColor(db.style.text.timer.shadowColor, { r = 0, g = 0, b = 0, a = 1 })
  db.style.text.timer.size = ClampRange(db.style.text.timer.size, 10, 40, 20)
  db.style.text.timer.shadowOffsetX = ClampRange(db.style.text.timer.shadowOffsetX, -4, 4, 1)
  db.style.text.timer.shadowOffsetY = ClampRange(db.style.text.timer.shadowOffsetY, -4, 4, -1)
  db.style.text.timer.outline = tostring(db.style.text.timer.outline or "THICKOUTLINE")

  db.style.text.status.readyColor = NormalizeColor(db.style.text.status.readyColor, { r = 0.45, g = 1.0, b = 0.55, a = 1 })
  db.style.text.status.cdColor = NormalizeColor(db.style.text.status.cdColor, { r = 1.0, g = 0.82, b = 0.35, a = 1 })
  db.style.text.status.shadowColor = NormalizeColor(db.style.text.status.shadowColor, { r = 0, g = 0, b = 0, a = 1 })
  db.style.text.status.size = ClampRange(db.style.text.status.size, 8, 24, 10)
  db.style.text.status.shadowOffsetX = ClampRange(db.style.text.status.shadowOffsetX, -4, 4, 1)
  db.style.text.status.shadowOffsetY = ClampRange(db.style.text.status.shadowOffsetY, -4, 4, -1)
  db.style.text.status.outline = tostring(db.style.text.status.outline or "OUTLINE")

  db.style.text.flash.color = NormalizeColor(db.style.text.flash.color, { r = 0.9, g = 0.95, b = 1.0, a = 1 })
  db.style.text.flash.shadowColor = NormalizeColor(db.style.text.flash.shadowColor, { r = 0, g = 0, b = 0, a = 1 })
  db.style.text.flash.size = ClampRange(db.style.text.flash.size, 8, 24, 11)
  db.style.text.flash.shadowOffsetX = ClampRange(db.style.text.flash.shadowOffsetX, -4, 4, 0)
  db.style.text.flash.shadowOffsetY = ClampRange(db.style.text.flash.shadowOffsetY, -4, 4, 0)
  db.style.text.flash.outline = tostring(db.style.text.flash.outline or "OUTLINE")

  db.style.glow.color = NormalizeColor(db.style.glow.color, { r = 0.2, g = 0.8, b = 1.0, a = 1 })
  db.style.glow.thresholdSeconds = ClampRange(db.style.glow.thresholdSeconds, 1, 30, 10)
  db.style.glow.pulseMin = ClampRange(db.style.glow.pulseMin, 0.0, 1.0, 0.4)
  db.style.glow.pulseMax = ClampRange(db.style.glow.pulseMax, db.style.glow.pulseMin, 1.0, 1.0)
  db.style.glow.edgeThickness = ClampRange(db.style.glow.edgeThickness, 1, 6, 2)
  db.style.glow.cornerSize = ClampRange(db.style.glow.cornerSize, 1, 8, 3)
  db.style.glow.cornerBoost = ClampRange(db.style.glow.cornerBoost, 0.0, 0.5, 0.15)
  db.style.glow.frameOutset = ClampRange(db.style.glow.frameOutset, 0, 8, 3)

  db.style.unlock.color = NormalizeColor(db.style.unlock.color, { r = 0.85, g = 0.75, b = 0.25, a = 1 })
  db.style.unlock.thickness = ClampRange(db.style.unlock.thickness, 1, 4, 1)
  db.style.unlock.frameOutset = ClampRange(db.style.unlock.frameOutset, 0, 8, 2)
  db.style.unlock.statusOffsetY = ClampRange(db.style.unlock.statusOffsetY, -6, 8, 1)
end

local function MigrateLegacyStyleSettings()
  if db.styleVersion and db.styleVersion >= STYLE_VERSION then
    NormalizeStyle()
    db.glowColor = db.style.glow.color
    return
  end

  NormalizeStyle()
  if type(db.glowColor) == "table" then
    db.style.glow.color.r = ClampUnit(db.glowColor.r, db.style.glow.color.r)
    db.style.glow.color.g = ClampUnit(db.glowColor.g, db.style.glow.color.g)
    db.style.glow.color.b = ClampUnit(db.glowColor.b, db.style.glow.color.b)
  end
  db.styleVersion = STYLE_VERSION
  db.activeStylePreset = db.activeStylePreset or "ElvUI Thin"
  db.styleProfiles = type(db.styleProfiles) == "table" and db.styleProfiles or {}
  db.glowColor = db.style.glow.color
end

local function EnsureStyleSchema()
  db.activeStylePreset = db.activeStylePreset or "ElvUI Thin"
  db.styleProfiles = type(db.styleProfiles) == "table" and db.styleProfiles or {}
  MigrateLegacyStyleSettings()
end

local function ApplyStylePreset(name)
  local preset = STYLE_PRESETS[name]
  if not preset then
    return false
  end
  db.style = DeepCopyTable(preset)
  db.activeStylePreset = name
  NormalizeStyle()
  db.glowColor = db.style.glow.color
  return true
end

local function SaveStyleProfile(name)
  local trimmed = strtrim(name or "")
  if trimmed == "" then
    return false, "Profile name is required."
  end
  db.styleProfiles[trimmed] = DeepCopyTable(db.style)
  return true
end

local function LoadStyleProfile(name)
  local trimmed = strtrim(name or "")
  if trimmed == "" then
    return false, "Profile name is required."
  end
  local profile = db.styleProfiles[trimmed]
  if type(profile) ~= "table" then
    return false, "Profile not found."
  end
  db.style = DeepCopyTable(profile)
  db.activeStylePreset = "Custom: " .. trimmed
  NormalizeStyle()
  db.glowColor = db.style.glow.color
  return true
end

local function DeleteStyleProfile(name)
  local trimmed = strtrim(name or "")
  if trimmed == "" then
    return false, "Profile name is required."
  end
  if not db.styleProfiles[trimmed] then
    return false, "Profile not found."
  end
  db.styleProfiles[trimmed] = nil
  return true
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

local function IsPotionAvailable()
  local itemID = db and db.potionItemID
  if not itemID then
    return false
  end

  local count = 0
  if C_Item and C_Item.GetItemCount then
    local ok, result = pcall(C_Item.GetItemCount, itemID, false, false, false)
    if ok then
      count = result or 0
    end
  elseif GetItemCount then
    count = GetItemCount(itemID, false, false) or 0
  end

  return count > 0
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

ClampUnit = function(value, fallback)
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

local function GetOutlineFlag(outline)
  local value = string.upper(tostring(outline or "NONE"))
  if value == "THICKOUTLINE" then
    return "THICKOUTLINE"
  end
  if value == "OUTLINE" then
    return "OUTLINE"
  end
  return ""
end

local function ApplyFrameStyle()
  if not ui.frame or not ui.panel or not db.style then
    return
  end

  local frameStyle = db.style.frame
  local iconStyle = db.style.icon
  local borderThickness = math.floor(frameStyle.borderThickness + 0.5)

  if ui.panel.SetBackdrop then
    ui.panel:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = borderThickness,
    })
    ui.panel:SetBackdropColor(
      frameStyle.backgroundColor.r,
      frameStyle.backgroundColor.g,
      frameStyle.backgroundColor.b,
      frameStyle.backgroundColor.a
    )
    ui.panel:SetBackdropBorderColor(
      frameStyle.borderColor.r,
      frameStyle.borderColor.g,
      frameStyle.borderColor.b,
      frameStyle.borderColor.a
    )
  elseif ui.panelBG then
    ui.panelBG:SetColorTexture(
      frameStyle.backgroundColor.r,
      frameStyle.backgroundColor.g,
      frameStyle.backgroundColor.b,
      frameStyle.backgroundColor.a
    )
  end

  if ui.icon then
    local inset = iconStyle.inset
    ui.icon:ClearAllPoints()
    ui.icon:SetPoint("TOPLEFT", ui.panel, "TOPLEFT", inset, -inset)
    ui.icon:SetPoint("BOTTOMRIGHT", ui.panel, "BOTTOMRIGHT", -inset, inset)
    local texInset = iconStyle.texCoordInset
    ui.icon:SetTexCoord(texInset, 1 - texInset, texInset, 1 - texInset)
    ui.icon:SetVertexColor(1, 1, 1, iconStyle.alpha)
    ui.icon:SetDesaturated(iconStyle.desaturated)
  end
end

local function ApplyCooldownStyle()
  if not ui.cooldown or not db.style then
    return
  end
  local cooldownStyle = db.style.cooldown
  if ui.cooldown.SetDrawEdge then
    ui.cooldown:SetDrawEdge(cooldownStyle.drawEdge)
  end
  if ui.cooldown.SetDrawSwipe then
    ui.cooldown:SetDrawSwipe(cooldownStyle.drawSwipe)
  end
  if ui.cooldown.SetSwipeColor then
    ui.cooldown:SetSwipeColor(
      cooldownStyle.swipeColor.r,
      cooldownStyle.swipeColor.g,
      cooldownStyle.swipeColor.b,
      cooldownStyle.swipeColor.a
    )
  end
end

local function ApplyTextStyle()
  if not db.style then
    return
  end
  local timerStyle = db.style.text.timer
  local statusStyle = db.style.text.status
  local flashStyle = db.style.text.flash

  if ui.timerText then
    ui.timerText:SetFont(STANDARD_TEXT_FONT, timerStyle.size, GetOutlineFlag(timerStyle.outline))
    ui.timerText:SetTextColor(timerStyle.color.r, timerStyle.color.g, timerStyle.color.b, timerStyle.color.a)
    ui.timerText:SetShadowOffset(timerStyle.shadowOffsetX, timerStyle.shadowOffsetY)
    ui.timerText:SetShadowColor(
      timerStyle.shadowColor.r,
      timerStyle.shadowColor.g,
      timerStyle.shadowColor.b,
      timerStyle.shadowColor.a
    )
  end

  if ui.statusText then
    local statusOffsetY = db.style.unlock.statusOffsetY or 1
    ui.statusText:ClearAllPoints()
    ui.statusText:SetPoint("BOTTOM", ui.frame, "TOP", 0, statusOffsetY)
    ui.statusText:SetFont(STANDARD_TEXT_FONT, statusStyle.size, GetOutlineFlag(statusStyle.outline))
    ui.statusText:SetShadowOffset(statusStyle.shadowOffsetX, statusStyle.shadowOffsetY)
    ui.statusText:SetShadowColor(
      statusStyle.shadowColor.r,
      statusStyle.shadowColor.g,
      statusStyle.shadowColor.b,
      statusStyle.shadowColor.a
    )
  end

  if ui.flashText then
    ui.flashText:SetFont(STANDARD_TEXT_FONT, flashStyle.size, GetOutlineFlag(flashStyle.outline))
    ui.flashText:SetTextColor(flashStyle.color.r, flashStyle.color.g, flashStyle.color.b, flashStyle.color.a)
    ui.flashText:SetShadowOffset(flashStyle.shadowOffsetX, flashStyle.shadowOffsetY)
    ui.flashText:SetShadowColor(
      flashStyle.shadowColor.r,
      flashStyle.shadowColor.g,
      flashStyle.shadowColor.b,
      flashStyle.shadowColor.a
    )
  end
end

local function ApplyUnlockStyle()
  if not ui.unlockFrame or not ui.unlockEdges or not db.style then
    return
  end
  local unlockStyle = db.style.unlock
  local color = unlockStyle.color
  local thickness = unlockStyle.thickness
  local outset = unlockStyle.frameOutset

  ui.unlockFrame:ClearAllPoints()
  ui.unlockFrame:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", -outset, outset)
  ui.unlockFrame:SetPoint("BOTTOMRIGHT", ui.frame, "BOTTOMRIGHT", outset, -outset)

  ui.unlockEdges.top:SetColorTexture(color.r, color.g, color.b, color.a)
  ui.unlockEdges.bottom:SetColorTexture(color.r, color.g, color.b, color.a)
  ui.unlockEdges.left:SetColorTexture(color.r, color.g, color.b, color.a)
  ui.unlockEdges.right:SetColorTexture(color.r, color.g, color.b, color.a)
  ui.unlockEdges.top:SetHeight(thickness)
  ui.unlockEdges.bottom:SetHeight(thickness)
  ui.unlockEdges.left:SetWidth(thickness)
  ui.unlockEdges.right:SetWidth(thickness)
end

local function ApplyGlowColor()
  if not ui.glowEdges or not ui.glowCorners or not db.style then
    return
  end
  local glowStyle = db.style.glow
  local color = glowStyle.color
  local cr = ClampUnit(color.r + glowStyle.cornerBoost, 1.0)
  local cg = ClampUnit(color.g + glowStyle.cornerBoost, 1.0)
  local cb = ClampUnit(color.b + glowStyle.cornerBoost, 1.0)

  for _, tex in ipairs(ui.glowEdges) do
    tex:SetColorTexture(color.r, color.g, color.b, color.a)
  end
  for _, tex in ipairs(ui.glowCorners) do
    tex:SetColorTexture(cr, cg, cb, color.a)
    tex:SetSize(glowStyle.cornerSize, glowStyle.cornerSize)
  end

  ui.glowEdges[1]:SetHeight(glowStyle.edgeThickness)
  ui.glowEdges[2]:SetHeight(glowStyle.edgeThickness)
  ui.glowEdges[3]:SetWidth(glowStyle.edgeThickness)
  ui.glowEdges[4]:SetWidth(glowStyle.edgeThickness)

  local outset = glowStyle.frameOutset
  ui.glowFrame:ClearAllPoints()
  ui.glowFrame:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", -outset, outset)
  ui.glowFrame:SetPoint("BOTTOMRIGHT", ui.frame, "BOTTOMRIGHT", outset, -outset)
end

local function ApplyAllStyles()
  NormalizeStyle()
  ApplyFrameStyle()
  ApplyCooldownStyle()
  ApplyTextStyle()
  ApplyUnlockStyle()
  ApplyGlowColor()
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
  if not ui.glowFrame or not db.style then
    return
  end

  local glowStyle = db.style.glow
  local glowActive = (not testMode) and (not state.buffActive) and state.cooldownActive and state.cooldownRemaining <= glowStyle.thresholdSeconds
  if not glowActive then
    ui.glowFrame:Hide()
    return
  end

  ui.glowFrame:Show()
  local minPulse = glowStyle.pulseMin
  local maxPulse = glowStyle.pulseMax
  local pulse = minPulse + ((maxPulse - minPulse) * (0.5 + 0.5 * math.sin(now * 10)))
  ui.glowFrame:SetAlpha(pulse)
end

local function Render()
  if not ui.frame or not ui.cooldown or not ui.timerText then
    return
  end

  local now = GetTime()
  local testMode = IsTestModeActive()
  local moveMode = not db.locked
  local hasTrackedState = state.buffActive or state.cooldownActive
  local showableAvailability = hasTrackedState or state.potionAvailable
  local show = moveMode or testMode or (showableAvailability and ShouldShowByFilters())

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
    local statusStyle = db.style and db.style.text and db.style.text.status
    if testMode or state.cooldownActive then
      ui.statusText:SetText("CD")
      if statusStyle then
        ui.statusText:SetTextColor(
          statusStyle.cdColor.r,
          statusStyle.cdColor.g,
          statusStyle.cdColor.b,
          statusStyle.cdColor.a
        )
      else
        ui.statusText:SetTextColor(1.0, 0.82, 0.35)
      end
    else
      ui.statusText:SetText("READY")
      if statusStyle then
        ui.statusText:SetTextColor(
          statusStyle.readyColor.r,
          statusStyle.readyColor.g,
          statusStyle.readyColor.b,
          statusStyle.readyColor.a
        )
      else
        ui.statusText:SetTextColor(0.45, 1.0, 0.55)
      end
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

  state.potionAvailable = IsPotionAvailable()
  state.buffActive, state.buffRemaining, state.buffExpiration, state.buffDuration, state.buffStart = GetBuffState()
  state.cooldownActive, state.cooldownRemaining, state.cooldownStart, state.cooldownDuration = GetCooldownState()

  if state.buffActive and not prevBuffActive then
    state.buffWarned = false
    state.readyAnnounced = false
  end

  if prevBuffActive and not state.buffActive then
    AlertPotionEnded()
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
    AlertPotionReady()
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
  ui.panelBG = nil
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
    ui.panelBG = panelBG
  end

  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", panel, "TOPLEFT", BOOTSTRAP_ICON_INSET, -BOOTSTRAP_ICON_INSET)
  icon:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -BOOTSTRAP_ICON_INSET, BOOTSTRAP_ICON_INSET)
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
    cooldown:SetSwipeColor(0, 0, 0, BOOTSTRAP_COOLDOWN_SWIPE_ALPHA)
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
  ui.unlockEdges = {
    top = unlockTop,
    bottom = unlockBottom,
    left = unlockLeft,
    right = unlockRight,
  }
  ui.glowFrame = glowFrame
  ui.glowEdges = { glowTop, glowBottom, glowLeft, glowRight }
  ui.glowCorners = corners
  ui.timerText = timerText
  ui.statusText = statusText
  ui.flashText = flashText
  ui.elapsed = 0

  ApplyFrameLock()
  ApplyFrameScale()
  ApplyAllStyles()
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
  if not name then
    anonymousSliderCount = anonymousSliderCount + 1
    name = "RecklessTrackerAnonSlider" .. anonymousSliderCount
  end
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

local function OpenStyleSettings()
  if Settings and Settings.OpenToCategory and styleSettingsCategoryID then
    Settings.OpenToCategory(styleSettingsCategoryID)
    return
  end
  if InterfaceOptionsFrame_OpenToCategory and styleSettingsPanel then
    InterfaceOptionsFrame_OpenToCategory(styleSettingsPanel)
    InterfaceOptionsFrame_OpenToCategory(styleSettingsPanel)
  end
end

local function CreateButton(parent, text, x, y, width, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  button:SetSize(width, 22)
  button:SetText(text)
  button:SetScript("OnClick", onClick)
  return button
end

local function CreateEditBox(parent, x, y, width, height)
  local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  editBox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  editBox:SetSize(width, height or 22)
  editBox:SetAutoFocus(false)
  editBox:SetTextInsets(6, 6, 0, 0)
  return editBox
end

local function SetColorSwatch(button, color)
  if not button.swatch then
    return
  end
  button.swatch:SetColorTexture(color.r, color.g, color.b, 1)
end

local function OpenColorPicker(initialColor, onChanged)
  local startColor = {
    r = ClampUnit(initialColor.r, 1),
    g = ClampUnit(initialColor.g, 1),
    b = ClampUnit(initialColor.b, 1),
  }

  local function Commit()
    local r, g, b
    if ColorPickerFrame and ColorPickerFrame.GetColorRGB then
      r, g, b = ColorPickerFrame:GetColorRGB()
    elseif ColorPickerFrame and ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
      local c1, c2, c3 = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
      if type(c1) == "table" then
        r, g, b = c1.r, c1.g, c1.b
      else
        r, g, b = c1, c2, c3
      end
    end
    if r and g and b then
      onChanged(ClampUnit(r, startColor.r), ClampUnit(g, startColor.g), ClampUnit(b, startColor.b))
    end
  end

  local function Cancel(previous)
    if type(previous) == "table" and previous.r then
      onChanged(ClampUnit(previous.r, startColor.r), ClampUnit(previous.g, startColor.g), ClampUnit(previous.b, startColor.b))
    else
      onChanged(startColor.r, startColor.g, startColor.b)
    end
  end

  if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
    ColorPickerFrame:SetupColorPickerAndShow({
      r = startColor.r,
      g = startColor.g,
      b = startColor.b,
      swatchFunc = Commit,
      opacityFunc = Commit,
      cancelFunc = Cancel,
      hasOpacity = false,
    })
    return
  end

  if ColorPickerFrame and ColorPickerFrame.SetColorRGB then
    ColorPickerFrame:SetColorRGB(startColor.r, startColor.g, startColor.b)
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.previousValues = { r = startColor.r, g = startColor.g, b = startColor.b }
    ColorPickerFrame.func = Commit
    ColorPickerFrame.cancelFunc = Cancel
    ColorPickerFrame:Show()
  end
end

local function NotifyStyleChanged()
  EnsureStyleSchema()
  ApplyAllStyles()
  RefreshState()
  Render()
end

local function CreateColorControl(parent, label, x, y, getColor, setColor)
  local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  title:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  title:SetText(label)

  local colorButton
  colorButton = CreateButton(parent, "Pick", x, y - 18, 60, function()
    local color = getColor()
    OpenColorPicker(color, function(r, g, b)
      local updated = getColor()
      updated.r = r
      updated.g = g
      updated.b = b
      setColor(updated)
      SetColorSwatch(colorButton, updated)
      NotifyStyleChanged()
    end)
  end)
  colorButton.swatch = colorButton:CreateTexture(nil, "ARTWORK")
  colorButton.swatch:SetPoint("LEFT", colorButton, "RIGHT", 6, 0)
  colorButton.swatch:SetSize(24, 14)

  local alphaSlider = CreateSlider(
    parent,
    nil,
    x + 104,
    y - 10,
    180,
    0.0,
    1.0,
    0.01,
    "Opacity",
    "0.00",
    "1.00",
    function() return getColor().a end,
    function(value)
      local updated = getColor()
      updated.a = ClampUnit(value, updated.a)
      setColor(updated)
      NotifyStyleChanged()
    end
  )

  local function Refresh()
    local current = getColor()
    SetColorSwatch(colorButton, current)
    alphaSlider:SetValue(current.a)
  end

  table.insert(styleControlRefreshers, Refresh)
  return Refresh
end

local function CreateOutlineCycle(parent, label, x, y, getValue, setValue)
  local options = { "NONE", "OUTLINE", "THICKOUTLINE" }
  local button = CreateButton(parent, "", x, y, 220, function(self)
    local current = string.upper(tostring(getValue() or "NONE"))
    local nextIndex = 1
    for i, value in ipairs(options) do
      if value == current then
        nextIndex = (i % #options) + 1
        break
      end
    end
    setValue(options[nextIndex])
    NotifyStyleChanged()
    self:SetText(label .. ": " .. options[nextIndex])
  end)

  local function Refresh()
    local current = string.upper(tostring(getValue() or "NONE"))
    button:SetText(label .. ": " .. current)
  end

  table.insert(styleControlRefreshers, Refresh)
  return Refresh
end

local function CreateTtsVoiceCycleButton(parent, x, y)
  local buttonWidth = 220
  local button = CreateButton(parent, "", x, y, buttonWidth, function(self)
    local options = GetSelectableTtsVoices()
    if #options == 0 then
      return
    end
    local currentID = db.alerts.ttsVoiceID
    local nextIndex = 1

    for i, option in ipairs(options) do
      if option.id == currentID then
        nextIndex = (i % #options) + 1
        break
      end
    end

    db.alerts.ttsVoiceID = options[nextIndex].id
    self:SetText("TTS voice:" .. " " .. options[nextIndex].label)
  end)

  local label = button:GetFontString()
  if label then
    label:SetWidth(buttonWidth - 16)
    label:SetWordWrap(false)
  end

  local function Refresh()
    local options = GetSelectableTtsVoices()
    if #options == 0 then
      button:SetText("TTS voice: none")
      button:SetEnabled(false)
      return
    end
    local currentLabel = "WoW default"

    for _, option in ipairs(options) do
      if option.id == db.alerts.ttsVoiceID then
        currentLabel = option.label
        break
      end
    end

    button:SetText("TTS voice:" .. " " .. currentLabel)
    button:SetEnabled(#options > 1)
  end

  return button, Refresh
end

local function RegisterSettingsPanel()
  styleControlRefreshers = {}

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
    { "Use TTS alerts", -290, function() return db.alerts.useTts end, function(v) db.alerts.useTts = v end },
    {
      "Lock frame",
      -350,
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

  local _, refreshTtsVoiceButton = CreateTtsVoiceCycleButton(panel, 16, -314)

  panel:SetScript("OnShow", function()
    for _, control in ipairs(checkboxes) do
      control.check:SetChecked(control.getter())
    end
    refreshTtsVoiceButton()
    if ui.scaleSlider then
      ui.scaleSlider:SetValue(db.scale)
    end
    if ui.scaleValueText then
      ui.scaleValueText:SetText(string.format("%.2f", db.scale))
    end
  end)

  local slider = CreateSlider(
    panel,
    "RecklessTrackerScaleSlider",
    20,
    -376,
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

  local openStyleButton = CreateButton(panel, "Open Style Settings", 20, -420, 220, function()
    OpenStyleSettings()
  end)
  openStyleButton:SetNormalFontObject("GameFontNormal")

  ui.scaleSlider = slider
  ui.scaleValueText = scaleValueText

  local stylePanel = CreateFrame("Frame")
  stylePanel.name = "RecklessTracker Style"
  stylePanel.parent = "RecklessTracker"

  local styleScroll = CreateFrame("ScrollFrame", "RecklessTrackerStyleScrollFrame", stylePanel, "UIPanelScrollFrameTemplate")
  styleScroll:SetPoint("TOPLEFT", stylePanel, "TOPLEFT", 4, -4)
  styleScroll:SetPoint("BOTTOMRIGHT", stylePanel, "BOTTOMRIGHT", -28, 4)

  local styleContent = CreateFrame("Frame", nil, styleScroll)
  styleContent:SetSize(540, 760)
  styleScroll:SetScrollChild(styleContent)

  local styleTitle = styleContent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  styleTitle:SetPoint("TOPLEFT", 16, -16)
  styleTitle:SetText("RecklessTracker Style")

  local styleSubtitle = styleContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  styleSubtitle:SetPoint("TOPLEFT", styleTitle, "BOTTOMLEFT", 0, -8)
  styleSubtitle:SetText("Customize colors, opacity, typography, glow, and profiles.")

  local presetHeader = styleContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  presetHeader:SetPoint("TOPLEFT", styleContent, "TOPLEFT", 16, -58)
  presetHeader:SetText("Built-in Presets")

  local function RefreshStylePanelControls()
    for _, refresh in ipairs(styleControlRefreshers) do
      refresh()
    end
    if ui.profileListText then
      local names = {}
      for name in pairs(db.styleProfiles) do
        table.insert(names, name)
      end
      table.sort(names)
      if #names > 0 then
        ui.profileListText:SetText("Active: " .. tostring(db.activeStylePreset) .. " | Profiles: " .. table.concat(names, ", "))
      else
        ui.profileListText:SetText("Active: " .. tostring(db.activeStylePreset) .. " | Profiles: none")
      end
    end
  end

  local function ApplyPresetAndRefresh(name)
    if ApplyStylePreset(name) then
      NotifyStyleChanged()
      RefreshStylePanelControls()
    end
  end

  CreateButton(styleContent, "Classic", 16, -78, 90, function() ApplyPresetAndRefresh("Classic") end)
  CreateButton(styleContent, "ElvUI Thin", 112, -78, 100, function() ApplyPresetAndRefresh("ElvUI Thin") end)
  CreateButton(styleContent, "High Contrast", 218, -78, 110, function() ApplyPresetAndRefresh("High Contrast") end)
  CreateButton(styleContent, "Reset Default", 334, -78, 110, function()
    db.style = NewDefaultStyle()
    db.activeStylePreset = "Custom"
    NotifyStyleChanged()
    RefreshStylePanelControls()
  end)

  local profileHeader = styleContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  profileHeader:SetPoint("TOPLEFT", styleContent, "TOPLEFT", 16, -110)
  profileHeader:SetText("Custom Profile")

  local profileInput = CreateEditBox(styleContent, 16, -130, 190, 22)
  profileInput:SetText("")

  CreateButton(styleContent, "Save", 214, -130, 70, function()
    local ok, err = SaveStyleProfile(profileInput:GetText())
    if not ok then
      Print(err)
      return
    end
    Print("Saved style profile.")
    RefreshStylePanelControls()
  end)
  CreateButton(styleContent, "Load", 290, -130, 70, function()
    local ok, err = LoadStyleProfile(profileInput:GetText())
    if not ok then
      Print(err)
      return
    end
    NotifyStyleChanged()
    RefreshStylePanelControls()
    Print("Loaded style profile.")
  end)
  CreateButton(styleContent, "Delete", 366, -130, 78, function()
    local ok, err = DeleteStyleProfile(profileInput:GetText())
    if not ok then
      Print(err)
      return
    end
    Print("Deleted style profile.")
    RefreshStylePanelControls()
  end)

  local profileListText = styleContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  profileListText:SetPoint("TOPLEFT", styleContent, "TOPLEFT", 16, -158)
  profileListText:SetText("Active: " .. tostring(db.activeStylePreset) .. " | Profiles: none")
  ui.profileListText = profileListText

  CreateColorControl(styleContent, "Frame Background", 16, -186,
    function() return db.style.frame.backgroundColor end,
    function(value) db.style.frame.backgroundColor = value end)
  CreateColorControl(styleContent, "Frame Border", 16, -230,
    function() return db.style.frame.borderColor end,
    function(value) db.style.frame.borderColor = value end)
  CreateColorControl(styleContent, "Cooldown Swipe", 16, -274,
    function() return db.style.cooldown.swipeColor end,
    function(value) db.style.cooldown.swipeColor = value end)
  CreateColorControl(styleContent, "Glow Color", 16, -318,
    function() return db.style.glow.color end,
    function(value) db.style.glow.color = value end)
  CreateColorControl(styleContent, "Timer Text", 16, -362,
    function() return db.style.text.timer.color end,
    function(value) db.style.text.timer.color = value end)
  CreateColorControl(styleContent, "Status READY Text", 16, -406,
    function() return db.style.text.status.readyColor end,
    function(value) db.style.text.status.readyColor = value end)
  CreateColorControl(styleContent, "Status CD Text", 16, -450,
    function() return db.style.text.status.cdColor end,
    function(value) db.style.text.status.cdColor = value end)

  local borderSlider = CreateSlider(
    styleContent, nil, 16, -510, 220, 1, 4, 1,
    "Border Thickness", "1", "4",
    function() return db.style.frame.borderThickness end,
    function(value)
      db.style.frame.borderThickness = ClampRange(value, 1, 4, db.style.frame.borderThickness)
      NotifyStyleChanged()
    end
  )
  table.insert(styleControlRefreshers, function() borderSlider:SetValue(db.style.frame.borderThickness) end)

  local insetSlider = CreateSlider(
    styleContent, nil, 16, -550, 220, 0, 8, 1,
    "Icon Inset", "0", "8",
    function() return db.style.icon.inset end,
    function(value)
      db.style.icon.inset = ClampRange(value, 0, 8, db.style.icon.inset)
      NotifyStyleChanged()
    end
  )
  table.insert(styleControlRefreshers, function() insetSlider:SetValue(db.style.icon.inset) end)

  local iconAlphaSlider = CreateSlider(
    styleContent, nil, 16, -590, 220, 0, 1, 0.01,
    "Icon Opacity", "0.00", "1.00",
    function() return db.style.icon.alpha end,
    function(value)
      db.style.icon.alpha = ClampUnit(value, db.style.icon.alpha)
      NotifyStyleChanged()
    end
  )
  table.insert(styleControlRefreshers, function() iconAlphaSlider:SetValue(db.style.icon.alpha) end)

  local timerSizeSlider = CreateSlider(
    styleContent, nil, 16, -630, 220, 10, 40, 1,
    "Timer Font Size", "10", "40",
    function() return db.style.text.timer.size end,
    function(value)
      db.style.text.timer.size = ClampRange(value, 10, 40, db.style.text.timer.size)
      NotifyStyleChanged()
    end
  )
  table.insert(styleControlRefreshers, function() timerSizeSlider:SetValue(db.style.text.timer.size) end)

  local statusSizeSlider = CreateSlider(
    styleContent, nil, 16, -670, 220, 8, 24, 1,
    "Status Font Size", "8", "24",
    function() return db.style.text.status.size end,
    function(value)
      db.style.text.status.size = ClampRange(value, 8, 24, db.style.text.status.size)
      NotifyStyleChanged()
    end
  )
  table.insert(styleControlRefreshers, function() statusSizeSlider:SetValue(db.style.text.status.size) end)

  local glowThresholdSlider = CreateSlider(
    styleContent, nil, 16, -710, 220, 1, 30, 1,
    "Glow Threshold (s)", "1", "30",
    function() return db.style.glow.thresholdSeconds end,
    function(value)
      db.style.glow.thresholdSeconds = ClampRange(value, 1, 30, db.style.glow.thresholdSeconds)
      NotifyStyleChanged()
    end
  )
  table.insert(styleControlRefreshers, function() glowThresholdSlider:SetValue(db.style.glow.thresholdSeconds) end)

  CreateOutlineCycle(styleContent, "Timer Outline", 260, -510,
    function() return db.style.text.timer.outline end,
    function(value) db.style.text.timer.outline = value end)
  CreateOutlineCycle(styleContent, "Status Outline", 260, -540,
    function() return db.style.text.status.outline end,
    function(value) db.style.text.status.outline = value end)

  stylePanel:SetScript("OnShow", function()
    EnsureStyleSchema()
    RefreshStylePanelControls()
  end)

  settingsPanel = panel
  styleSettingsPanel = stylePanel
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "RecklessTracker")
    Settings.RegisterAddOnCategory(category)
    settingsCategoryID = category:GetID()

    local styleCategory = Settings.RegisterCanvasLayoutCategory(stylePanel, "RecklessTracker Style")
    Settings.RegisterAddOnCategory(styleCategory)
    styleSettingsCategoryID = styleCategory:GetID()
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
    InterfaceOptions_AddCategory(stylePanel)
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

  db.style.glow.color.r = ClampUnit(r, db.style.glow.color.r)
  db.style.glow.color.g = ClampUnit(g, db.style.glow.color.g)
  db.style.glow.color.b = ClampUnit(b, db.style.glow.color.b)
  db.glowColor = db.style.glow.color
  NotifyStyleChanged()
  Print(string.format(
    "Glow color set to R %.2f G %.2f B %.2f",
    db.style.glow.color.r,
    db.style.glow.color.g,
    db.style.glow.color.b
  ))
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
        db.style.glow.color.r,
        db.style.glow.color.g,
        db.style.glow.color.b
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
  EnsureStyleSchema()
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
  addon:RegisterEvent("BAG_UPDATE")
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
