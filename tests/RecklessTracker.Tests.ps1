Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-True {
  param(
    [Parameter(Mandatory = $true)]
    [bool]$Condition,

    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if (-not $Condition) {
    throw $Message
  }
}

function Assert-GreaterThan {
  param(
    [Parameter(Mandatory = $true)]
    [double]$Actual,

    [Parameter(Mandatory = $true)]
    [double]$Threshold,

    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if (-not ($Actual -gt $Threshold)) {
    throw "$Message (actual: $Actual, threshold: $Threshold)"
  }
}

function Assert-Match {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Actual,

    [Parameter(Mandatory = $true)]
    [string]$Pattern,

    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if ($Actual -notmatch $Pattern) {
    throw "$Message (pattern: $Pattern)"
  }
}

function Assert-NotMatch {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Actual,

    [Parameter(Mandatory = $true)]
    [string]$Pattern,

    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if ($Actual -match $Pattern) {
    throw "$Message (pattern unexpectedly matched: $Pattern)"
  }
}

Describe "RecklessTracker TOC compatibility" {
  BeforeAll {
    . (Join-Path $PSScriptRoot "TestContext.ps1")
    Initialize-TestContext
  }

  It "has a usable build info source path" {
    Assert-True (Test-Path -LiteralPath $script:buildInfoPath) "Expected build info source path to exist"
  }

  It "includes the active client interface number from .build.info" {
    Assert-True ((@($script:tocInterfaces) -contains $script:clientInterface)) "Expected TOC interfaces to include active client interface"
  }

  It "contains at least one numeric interface value" {
    Assert-GreaterThan $script:tocInterfaces.Count 0 "Expected TOC to contain at least one numeric interface value"
  }
}

Describe "RecklessTracker startup hardening" {
  BeforeAll {
    . (Join-Path $PSScriptRoot "TestContext.ps1")
    Initialize-TestContext
  }

  It "registers /rt slash commands" {
    Assert-Match $script:luaSource 'SLASH_RECKLESSTRACKER1\s*=\s*"/rt"' "Expected slash command alias registration"
    Assert-Match $script:luaSource 'SlashCmdList\.RECKLESSTRACKER\s*=\s*function' "Expected slash command handler registration"
  }

  It "registers slash commands before settings init in Initialize" {
    $match = [regex]::Match($script:luaSource, 'local function Initialize\(\)([\s\S]*?)\nend')
    Assert-True $match.Success "Expected to find Initialize function body"
    $body = $match.Groups[1].Value
    $slashIndex = $body.IndexOf("RegisterSlashCommands()")
    $settingsIndex = $body.IndexOf("RegisterSettingsPanel")
    Assert-GreaterThan $slashIndex -1 "Expected RegisterSlashCommands call in Initialize"
    Assert-GreaterThan $settingsIndex -1 "Expected RegisterSettingsPanel call in Initialize"
    Assert-GreaterThan $settingsIndex $slashIndex "Expected slash registration before settings init"
  }

  It "protects settings init with pcall so startup still completes" {
    Assert-Match $script:luaSource 'pcall\(RegisterSettingsPanel\)' "Expected settings registration to be wrapped in pcall"
  }

  It "guards Render when ui.frame is unavailable" {
    Assert-Match $script:luaSource 'local function Render\(\)[\s\S]*if not ui\.frame[\s\S]*return' "Expected Render to guard missing frame"
  }

  It "protects frame creation in Initialize" {
    Assert-Match $script:luaSource 'pcall\(CreateTrackerFrame\)' "Expected frame creation to be wrapped in pcall"
  }

  It "sets statusText font before setting status text content" {
    $match = [regex]::Match($script:luaSource, 'local statusText = textLayer:CreateFontString\([\s\S]*?ui\.statusText = statusText')
    Assert-True $match.Success "Expected status text creation block"
    $block = $match.Value
    $fontIndex = $block.IndexOf("statusText:SetFont(")
    $textIndex = $block.IndexOf("statusText:SetText(")
    Assert-GreaterThan $fontIndex -1 "Expected statusText font assignment"
    Assert-GreaterThan $textIndex -1 "Expected statusText text assignment"
    Assert-GreaterThan $textIndex $fontIndex "Expected font assignment before text assignment"
  }

  It "does not reference removed bootstrap constants in CreateTrackerFrame" {
    $match = [regex]::Match($script:luaSource, 'local function CreateTrackerFrame\(\)([\s\S]*?)\nend')
    Assert-True $match.Success "Expected CreateTrackerFrame function body"
    $block = $match.Value
    Assert-NotMatch $block '\bICON_INSET\b' "Did not expect removed ICON_INSET constant reference"
    Assert-NotMatch $block '\bCOOLDOWN_SWIPE_ALPHA\b' "Did not expect removed COOLDOWN_SWIPE_ALPHA constant reference"
  }
}

Describe "RecklessTracker inventory visibility" {
  BeforeAll {
    . (Join-Path $PSScriptRoot "TestContext.ps1")
    Initialize-TestContext
  }

  It "checks configured potion bag availability with GetItemCount" {
    Assert-Match $script:luaSource 'local function IsPotionAvailable\(\)[\s\S]*GetItemCount' "Expected potion availability helper to query bag count"
  }

  It "refreshes potion availability before rendering" {
    Assert-Match $script:luaSource 'state\.potionAvailable\s*=\s*IsPotionAvailable\(\)' "Expected render path to refresh potion availability"
  }

  It "hides idle filtered display when the potion is not in bags" {
    $match = [regex]::Match($script:luaSource, 'local function Render\(\)([\s\S]*?)\nend')
    Assert-True $match.Success "Expected Render function body"
    $body = $match.Groups[1].Value

    Assert-Match $body 'local hasTrackedState\s*=\s*state\.buffActive\s+or\s+state\.cooldownActive' "Expected Render to detect tracked state"
    Assert-Match $body 'local showableAvailability\s*=\s*hasTrackedState\s+or\s+state\.potionAvailable' "Expected Render to gate idle visibility on bag availability"
    Assert-Match $body 'showableAvailability\s+and\s+ShouldShowByFilters\(\)' "Expected filtered visibility to require showable availability"
  }

  It "listens for bag updates so the icon appears after acquiring potions" {
    Assert-Match $script:luaSource 'addon:RegisterEvent\("BAG_UPDATE"\)' "Expected BAG_UPDATE registration"
  }
}

Describe "RecklessTracker TTS alerts" {
  BeforeAll {
    . (Join-Path $PSScriptRoot "TestContext.ps1")
    Initialize-TestContext
  }

  It "adds a saved option to use TTS for potion ready and ended alerts" {
    Assert-Match $script:luaSource 'useTts\s*=\s*false' "Expected TTS option in defaults"
  }

  It "exposes a settings checkbox for TTS alerts" {
    Assert-Match $script:luaSource '"Use TTS alerts"' "Expected TTS checkbox label"
    Assert-Match $script:luaSource 'db\.alerts\.useTts\s*=\s*v' "Expected TTS checkbox binding"
  }

  It "adds a saved option for a per-addon TTS voice selection" {
    Assert-Match $script:luaSource 'ttsVoiceID\s*=\s*nil' "Expected saved TTS voice setting"
  }

  It "resolves the saved TTS voice through the discovered voice list and falls back to the default helper" {
    $match = [regex]::Match($script:luaSource, 'local function ResolveTtsVoiceID\(\)([\s\S]*?)\nend')
    Assert-True $match.Success "Expected ResolveTtsVoiceID function body"
    $body = $match.Groups[1].Value

    Assert-Match $body 'db\.alerts\.ttsVoiceID' "Expected saved TTS voice lookup"
    Assert-Match $body 'GetSelectableTtsVoices\(\)' "Expected selectable voice list lookup"
    Assert-Match $body 'GetDefaultTtsVoiceID\(\)' "Expected fallback to default voice helper"
  }

  It "discovers selectable TTS voices from the voice chat API in a stable order" {
    $match = [regex]::Match($script:luaSource, 'local function GetSelectableTtsVoices\(\)([\s\S]*?)\nend')
    Assert-True $match.Success "Expected GetSelectableTtsVoices function body"
    $body = $match.Groups[1].Value

    Assert-Match $body 'if not \(C_VoiceChat and type\(C_VoiceChat\.GetTtsVoices\) == "function"\) then' "Expected voice chat API guard"
    Assert-Match $body 'C_VoiceChat\.GetTtsVoices' "Expected voice discovery API usage"
    Assert-Match $body 'table\.sort\(voices' "Expected stable voice ordering"
    Assert-Match $body 'voice\.voiceID' "Expected voice IDs in selector options"
    Assert-Match $body 'voice\.name' "Expected voice names in selector options"
    Assert-Match $body 'label\s*=\s*"Voice "\s*\.\.\s*voice\.voiceID' "Expected numeric fallback label for unnamed voices"
    Assert-Match $body 'label\s*=\s*"WoW default"' "Expected WoW default selector label"
  }

  It "uses the standard TTS voice option helper" {
    Assert-Match $script:luaSource 'STANDARD_TTS_VOICE_TYPE' "Expected standard TTS voice type constant"
    Assert-Match $script:luaSource 'Enum\.TtsVoiceType\.Standard' "Expected standard TTS voice type enum usage"
    Assert-Match $script:luaSource 'C_TTSSettings\.GetVoiceOptionID\(STANDARD_TTS_VOICE_TYPE\)' "Expected standard voice option lookup"
  }

  It "guards the TTS voice cycle button against an empty option list" {
    $match = [regex]::Match($script:luaSource, 'local function CreateTtsVoiceCycleButton\(parent, x, y\)([\s\S]*?)\nend')
    Assert-True $match.Success "Expected CreateTtsVoiceCycleButton function body"
    $body = $match.Groups[1].Value

    Assert-Match $body 'if #options == 0 then' "Expected empty-options guard"
    Assert-Match $body 'SetEnabled\(#options > 1\)' "Expected selector enable guard"
    Assert-Match $body '"TTS voice:"' "Expected TTS voice selector label"
  }

  It "clamps the TTS voice button label to the button width so long voice names ellipsize (regression: text overflow past button border)" {
    $match = [regex]::Match($script:luaSource, 'local function CreateTtsVoiceCycleButton\(parent, x, y\)([\s\S]*?)\nend')
    Assert-True $match.Success "Expected CreateTtsVoiceCycleButton function body"
    $body = $match.Groups[1].Value

    Assert-Match $body 'GetFontString\(\)' "Expected access to the button's font string"
    Assert-Match $body 'SetWordWrap\(false\)' "Expected SetWordWrap(false) so long labels truncate instead of wrapping"
    Assert-Match $body ':SetWidth\(' "Expected explicit font string width clamp"
  }

  It "uses the current mainline SpeakText signature with player TTS settings" {
    Assert-Match $script:luaSource 'local function SpeakTtsAlert\(text\)' "Expected TTS alert helper"
    Assert-Match $script:luaSource 'C_TTSSettings\.GetVoiceOptionID' "Expected TTS voice settings lookup"
    Assert-Match $script:luaSource 'C_TTSSettings\.GetSpeechRate' "Expected speech rate lookup"
    Assert-Match $script:luaSource 'C_TTSSettings\.GetSpeechVolume' "Expected speech volume lookup"
    Assert-Match $script:luaSource 'pcall\(C_VoiceChat\.SpeakText,\s*voiceID,\s*text,\s*rate,\s*volume,\s*true\)' "Expected current SpeakText signature"
  }

  It "routes cooldown ready through the TTS-or-sound alert helper" {
    Assert-Match $script:luaSource 'local function AlertPotionReady\(\)[\s\S]*SpeakTtsAlert\("potion ready"\)[\s\S]*SafePlaySound\(SOUND_COOLDOWN_READY\)' "Expected cooldown-ready alert routing"
    Assert-Match $script:luaSource 'TriggerReadyFlash\(\)[\s\S]*AlertPotionReady\(\)' "Expected ready flash to trigger alert helper"
  }

  It "announces potion ended when the buff transitions off" {
    Assert-Match $script:luaSource 'local function AlertPotionEnded\(\)[\s\S]*SpeakTtsAlert\("potion ended"\)' "Expected buff-end TTS alert helper"
    Assert-Match $script:luaSource 'prevBuffActive\s+and\s+not state\.buffActive[\s\S]*AlertPotionEnded\(\)' "Expected buff-end transition alert"
  }

  It "keeps the 5 second buff warning on the existing sound path" {
    $warningBlock = [regex]::Match($script:luaSource, 'if state\.buffRemaining <= BUFF_WARNING_SECONDS[\s\S]*?state\.buffWarned = true')
    Assert-True $warningBlock.Success "Expected buff warning block"
    Assert-Match $warningBlock.Value 'SafePlaySound\(SOUND_BUFF_WARNING\)' "Expected existing warning sound path"
    Assert-NotMatch $warningBlock.Value 'SpeakTtsAlert' "Did not expect TTS in 5 second warning block"
  }
}

Describe "RecklessTracker style system" {
  BeforeAll {
    . (Join-Path $PSScriptRoot "TestContext.ps1")
    Initialize-TestContext
  }

  It "defines a structured style schema in defaults" {
    Assert-Match $script:luaSource 'style\s*=\s*\{' "Expected structured style defaults"
    Assert-Match $script:luaSource 'styleProfiles\s*=\s*\{' "Expected style profiles defaults"
    Assert-Match $script:luaSource 'activeStylePreset' "Expected active style preset default"
  }

  It "includes style migration/version handling" {
    Assert-Match $script:luaSource 'styleVersion' "Expected style version handling"
    Assert-Match $script:luaSource 'MigrateLegacyStyleSettings' "Expected style migration helper"
    Assert-Match $script:luaSource 'EnsureStyleSchema' "Expected style schema validation"
  }

  It "uses a color picker control for style colors" {
    Assert-Match $script:luaSource 'OpenColorPicker' "Expected color picker usage"
    Assert-Match $script:luaSource 'ColorPickerFrame' "Expected Blizzard color picker integration"
  }

  It "exposes style presets and custom profile actions in settings" {
    Assert-Match $script:luaSource 'ApplyStylePreset' "Expected style preset application action"
    Assert-Match $script:luaSource 'SaveStyleProfile' "Expected style profile save action"
    Assert-Match $script:luaSource 'LoadStyleProfile' "Expected style profile load action"
    Assert-Match $script:luaSource 'DeleteStyleProfile' "Expected style profile delete action"
  }

  It "wraps the style panel children in a UIPanelScrollFrameTemplate ScrollFrame (regression: bottom controls clipped below canvas)" {
    Assert-Match $script:luaSource 'CreateFrame\(\s*"ScrollFrame"[\s\S]*?"UIPanelScrollFrameTemplate"' "Expected UIPanelScrollFrameTemplate ScrollFrame in style panel"
    Assert-Match $script:luaSource ':SetScrollChild\(' "Expected SetScrollChild on the style ScrollFrame"
  }

  It "anchors the style preset header far enough below the subtitle to avoid overlap (regression: 'Built-in Presets' painted over 'Customize...' subtitle)" {
    $match = [regex]::Match($script:luaSource, 'presetHeader:SetPoint\(\s*"TOPLEFT"\s*,[^,]+,\s*"TOPLEFT"\s*,\s*\d+\s*,\s*(-?\d+)')
    Assert-True $match.Success "Expected presetHeader anchor"
    [int]$y = $match.Groups[1].Value
    Assert-True ($y -le -58) "Expected presetHeader y <= -58 to clear subtitle (actual: $y)"
  }

  It "places the Border Thickness slider below the final color row Pick button (regression: Pick button overlapped slider label)" {
    $match = [regex]::Match($script:luaSource, '(?s)CreateSlider\(\s*[A-Za-z_]+,\s*[^,]+,\s*\d+,\s*(-?\d+)[\s\S]{0,200}?"Border Thickness"')
    Assert-True $match.Success "Expected Border Thickness slider creation"
    [int]$y = $match.Groups[1].Value
    Assert-True ($y -le -490) "Expected Border Thickness slider y <= -490 to clear the last Pick button (actual: $y)"
  }

  It "forward-declares colorButton so OpenColorPicker callback captures the local upvalue (regression: swatchFunc nil button)" {
    $match = [regex]::Match($script:luaSource, 'local function CreateColorControl\(parent, label, x, y, getColor, setColor\)([\s\S]*?)\nend')
    Assert-True $match.Success "Expected CreateColorControl function body"
    $body = $match.Groups[1].Value

    Assert-NotMatch $body 'local colorButton\s*=\s*CreateButton' "Expected colorButton to NOT be initialized on its declaration line (the inner OpenColorPicker callback captures it; declaring with initializer makes the closure resolve colorButton as a nil global)"
    Assert-Match $body '(?m)^\s*local colorButton\s*$' "Expected forward-declared 'local colorButton' on its own line"
    Assert-Match $body '(?m)^\s*colorButton\s*=\s*CreateButton\(' "Expected separate assignment to colorButton = CreateButton(...)"
    Assert-Match $body 'SetColorSwatch\(colorButton,' "Expected SetColorSwatch to still receive colorButton from the closure"
  }
}

Describe "RecklessTracker package isolation" {
  BeforeAll {
    . (Join-Path $PSScriptRoot "TestContext.ps1")
    Initialize-TestContext
  }

  It "uses package-as to publish only the addon folder name" {
    Assert-Match $script:pkgmetaSource 'package-as:\s*RecklessTracker' "Expected package-as directive"
  }

  It "includes a release toc at repo root for packager discovery" {
    Assert-True (Test-Path -LiteralPath $script:releaseTocPath) "Expected root release TOC"
    $releaseToc = Get-Content -LiteralPath $script:releaseTocPath -Raw
    Assert-Match $releaseToc '^##\s*Interface\s*:' "Expected interface line in root release TOC"
    Assert-Match $releaseToc 'RecklessTracker\\RecklessTracker\.lua' "Expected addon entry in root release TOC"
  }

  It "ignores internal development files and folders from release package" {
    @(
      '\.github',
      'debug',
      'docs',
      'scripts',
      'tests',
      'addon-dev-learning\.md'
    ) | ForEach-Object {
      Assert-Match $script:pkgmetaSource ("-\s*" + $_) "Expected .pkgmeta ignore entry for $_"
    }
  }
}


