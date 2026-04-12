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
    [string]$BuildInfoPath = "F:\World of Warcraft\.build.info"
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

$repoRoot = Split-Path -Parent $PSScriptRoot
$addonDir = Join-Path $repoRoot "RecklessTracker"
$tocPath = Join-Path $addonDir "RecklessTracker.toc"
$luaPath = Join-Path $addonDir "RecklessTracker.lua"
$pkgmetaPath = Join-Path $repoRoot ".pkgmeta"
$luaSource = Get-Content -LiteralPath $luaPath -Raw
$pkgmetaSource = Get-Content -LiteralPath $pkgmetaPath -Raw
$tocInterfaces = [string[]](Get-TocInterfaceValues -TocPath $tocPath)
$clientInterface = Get-ClientInterfaceFromBuildInfo

Describe "RecklessTracker TOC compatibility" {
  It "includes the active client interface number from .build.info" {
    (@($tocInterfaces) -contains $clientInterface) | Should Be $true
  }

  It "contains at least one numeric interface value" {
    $tocInterfaces.Count | Should BeGreaterThan 0
  }
}

Describe "RecklessTracker startup hardening" {
  It "registers /rt slash commands" {
    $luaSource | Should Match 'SLASH_RECKLESSTRACKER1\s*=\s*"/rt"'
    $luaSource | Should Match 'SlashCmdList\.RECKLESSTRACKER\s*=\s*function'
  }

  It "registers slash commands before settings init in Initialize" {
    $match = [regex]::Match($luaSource, 'local function Initialize\(\)([\s\S]*?)\nend')
    $match.Success | Should Be $true
    $body = $match.Groups[1].Value
    $slashIndex = $body.IndexOf("RegisterSlashCommands()")
    $settingsIndex = $body.IndexOf("RegisterSettingsPanel")
    $slashIndex | Should BeGreaterThan -1
    $settingsIndex | Should BeGreaterThan -1
    $settingsIndex | Should BeGreaterThan $slashIndex
  }

  It "protects settings init with pcall so startup still completes" {
    $luaSource | Should Match 'pcall\(RegisterSettingsPanel\)'
  }

  It "guards Render when ui.frame is unavailable" {
    $luaSource | Should Match 'local function Render\(\)[\s\S]*if not ui\.frame[\s\S]*return'
  }

  It "protects frame creation in Initialize" {
    $luaSource | Should Match 'pcall\(CreateTrackerFrame\)'
  }

  It "sets statusText font before setting status text content" {
    $match = [regex]::Match($luaSource, 'local statusText = textLayer:CreateFontString\([\s\S]*?ui\.statusText = statusText')
    $match.Success | Should Be $true
    $block = $match.Value
    $fontIndex = $block.IndexOf("statusText:SetFont(")
    $textIndex = $block.IndexOf("statusText:SetText(")
    $fontIndex | Should BeGreaterThan -1
    $textIndex | Should BeGreaterThan -1
    $textIndex | Should BeGreaterThan $fontIndex
  }
}

Describe "RecklessTracker package isolation" {
  It "uses package-as to publish only the addon folder name" {
    $pkgmetaSource | Should Match 'package-as:\s*RecklessTracker'
  }

  It "maps nested addon folder into package root for TOC discovery" {
    $pkgmetaSource | Should Match 'move-folders:'
    $pkgmetaSource | Should Match 'RecklessTracker:\s*RecklessTracker'
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
      $pkgmetaSource | Should Match ("-\s*" + $_)
    }
  }
}
