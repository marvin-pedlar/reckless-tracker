Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Convert-VersionToInterface {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Version
  )

  if ($Version -notmatch '^(\d+)\.(\d+)\.(\d+)') {
    throw "Unable to parse version string '$Version'"
  }

  $major = [int]$Matches[1]
  $minor = [int]$Matches[2]
  $patch = [int]$Matches[3]
  return ("{0}{1:D2}{2:D2}" -f $major, $minor, $patch)
}

function Get-ClientInterfaceFromBuildInfo {
  param(
    [Parameter(Mandatory = $true)]
    [string]$BuildInfoPath
  )

  if (-not (Test-Path -LiteralPath $BuildInfoPath)) {
    throw "Build info not found at '$BuildInfoPath'"
  }

  $lines = Get-Content -LiteralPath $BuildInfoPath
  if ($lines.Count -lt 2) {
    throw "Unexpected .build.info format (needs header + at least one row)"
  }

  $header = $lines[0] -split '\|'
  $activeIndex = -1
  $versionIndex = -1
  for ($i = 0; $i -lt $header.Count; $i++) {
    if ($header[$i] -like "Active!*") { $activeIndex = $i }
    if ($header[$i] -like "Version!*") { $versionIndex = $i }
  }

  if ($activeIndex -lt 0 -or $versionIndex -lt 0) {
    throw "Could not locate Active/Version columns in .build.info header"
  }

  $activeRow = $null
  for ($i = 1; $i -lt $lines.Count; $i++) {
    $cols = $lines[$i] -split '\|'
    if ($cols.Count -gt $activeIndex -and $cols[$activeIndex] -eq "1") {
      $activeRow = $cols
      break
    }
  }

  if (-not $activeRow) {
    throw "No active product row found in .build.info"
  }

  if ($activeRow.Count -le $versionIndex) {
    throw "Active row missing Version value"
  }

  return Convert-VersionToInterface -Version $activeRow[$versionIndex]
}

function Get-TocInterfaceValues {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TocPath
  )

  $line = Get-Content -LiteralPath $TocPath |
    Where-Object { $_ -match '^##\s*Interface\s*:' } |
    Select-Object -First 1

  if (-not $line) {
    throw "TOC has no ## Interface line"
  }

  $rawValue = ($line -split ':', 2)[1]
  return @(
    $rawValue -split ',' |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_ -match '^\d+$' }
  )
}

function Initialize-TestContext {
  $initializedVar = Get-Variable -Name testContextInitialized -Scope Script -ErrorAction SilentlyContinue
  if ($initializedVar -and $initializedVar.Value) {
    return
  }

  $script:repoRoot = Split-Path -Parent $PSScriptRoot
  $script:addonDir = Join-Path $script:repoRoot "RecklessTracker"
  $script:tocPath = Join-Path $script:addonDir "RecklessTracker.toc"
  $script:releaseTocPath = Join-Path $script:repoRoot "RecklessTracker.toc"
  $script:luaPath = Join-Path $script:addonDir "RecklessTracker.lua"
  $script:pkgmetaPath = Join-Path $script:repoRoot ".pkgmeta"

  $script:luaSource = Get-Content -LiteralPath $script:luaPath -Raw
  $script:pkgmetaSource = Get-Content -LiteralPath $script:pkgmetaPath -Raw
  $script:tocInterfaces = [string[]](Get-TocInterfaceValues -TocPath $script:tocPath)

  $localBuildInfoPath = "F:\World of Warcraft\.build.info"
  $fixtureBuildInfoPath = Join-Path $PSScriptRoot "fixtures\build.info"

  if ($env:RT_BUILD_INFO_PATH -and (Test-Path -LiteralPath $env:RT_BUILD_INFO_PATH)) {
    $script:buildInfoPath = $env:RT_BUILD_INFO_PATH
  } elseif (Test-Path -LiteralPath $localBuildInfoPath) {
    $script:buildInfoPath = $localBuildInfoPath
  } else {
    $script:buildInfoPath = $fixtureBuildInfoPath
  }

  $script:clientInterface = Get-ClientInterfaceFromBuildInfo -BuildInfoPath $script:buildInfoPath
  $script:testContextInitialized = $true
}

Describe "RecklessTracker TOC compatibility" {
  BeforeAll {
    Initialize-TestContext
  }

  It "has a usable build info source path" {
    (Test-Path -LiteralPath $script:buildInfoPath) | Should Be $true
  }

  It "includes the active client interface number from .build.info" {
    (@($script:tocInterfaces) -contains $script:clientInterface) | Should Be $true
  }

  It "contains at least one numeric interface value" {
    $script:tocInterfaces.Count | Should BeGreaterThan 0
  }
}

Describe "RecklessTracker startup hardening" {
  BeforeAll {
    Initialize-TestContext
  }

  It "registers /rt slash commands" {
    $script:luaSource | Should Match 'SLASH_RECKLESSTRACKER1\s*=\s*"/rt"'
    $script:luaSource | Should Match 'SlashCmdList\.RECKLESSTRACKER\s*=\s*function'
  }

  It "registers slash commands before settings init in Initialize" {
    $match = [regex]::Match($script:luaSource, 'local function Initialize\(\)([\s\S]*?)\nend')
    $match.Success | Should Be $true
    $body = $match.Groups[1].Value
    $slashIndex = $body.IndexOf("RegisterSlashCommands()")
    $settingsIndex = $body.IndexOf("RegisterSettingsPanel")
    $slashIndex | Should BeGreaterThan -1
    $settingsIndex | Should BeGreaterThan -1
    $settingsIndex | Should BeGreaterThan $slashIndex
  }

  It "protects settings init with pcall so startup still completes" {
    $script:luaSource | Should Match 'pcall\(RegisterSettingsPanel\)'
  }

  It "guards Render when ui.frame is unavailable" {
    $script:luaSource | Should Match 'local function Render\(\)[\s\S]*if not ui\.frame[\s\S]*return'
  }

  It "protects frame creation in Initialize" {
    $script:luaSource | Should Match 'pcall\(CreateTrackerFrame\)'
  }

  It "sets statusText font before setting status text content" {
    $match = [regex]::Match($script:luaSource, 'local statusText = textLayer:CreateFontString\([\s\S]*?ui\.statusText = statusText')
    $match.Success | Should Be $true
    $block = $match.Value
    $fontIndex = $block.IndexOf("statusText:SetFont(")
    $textIndex = $block.IndexOf("statusText:SetText(")
    $fontIndex | Should BeGreaterThan -1
    $textIndex | Should BeGreaterThan -1
    $textIndex | Should BeGreaterThan $fontIndex
  }
}

Describe "RecklessTracker style system" {
  BeforeAll {
    Initialize-TestContext
  }

  It "defines a structured style schema in defaults" {
    $script:luaSource | Should Match 'style\s*=\s*\{'
    $script:luaSource | Should Match 'styleProfiles\s*=\s*\{'
    $script:luaSource | Should Match 'activeStylePreset'
  }

  It "includes style migration/version handling" {
    $script:luaSource | Should Match 'styleVersion'
    $script:luaSource | Should Match 'MigrateLegacyStyleSettings'
    $script:luaSource | Should Match 'EnsureStyleSchema'
  }

  It "uses a color picker control for style colors" {
    $script:luaSource | Should Match 'OpenColorPicker'
    $script:luaSource | Should Match 'ColorPickerFrame'
  }

  It "exposes style presets and custom profile actions in settings" {
    $script:luaSource | Should Match 'ApplyStylePreset'
    $script:luaSource | Should Match 'SaveStyleProfile'
    $script:luaSource | Should Match 'LoadStyleProfile'
    $script:luaSource | Should Match 'DeleteStyleProfile'
  }
}

Describe "RecklessTracker package isolation" {
  BeforeAll {
    Initialize-TestContext
  }

  It "uses package-as to publish only the addon folder name" {
    $script:pkgmetaSource | Should Match 'package-as:\s*RecklessTracker'
  }

  It "includes a release toc at repo root for packager discovery" {
    (Test-Path -LiteralPath $script:releaseTocPath) | Should Be $true
    $releaseToc = Get-Content -LiteralPath $script:releaseTocPath -Raw
    $releaseToc | Should Match '^##\s*Interface\s*:'
    $releaseToc | Should Match 'RecklessTracker\\RecklessTracker\.lua'
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
      $script:pkgmetaSource | Should Match ("-\s*" + $_)
    }
  }
}


