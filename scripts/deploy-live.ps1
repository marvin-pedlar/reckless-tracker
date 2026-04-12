param(
  [string]$LiveAddonDir = "F:\World of Warcraft\_retail_\Interface\AddOns\RecklessTracker"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $repoRoot "RecklessTracker"
$testPath = Join-Path $repoRoot "tests\RecklessTracker.Tests.ps1"

if (-not (Test-Path -LiteralPath $LiveAddonDir)) {
  throw "Live addon directory not found: $LiveAddonDir"
}

if (-not (Get-Module -ListAvailable Pester)) {
  throw "Pester module not found. Install Pester to run tests."
}

$result = Invoke-Pester -Script $testPath -PassThru
if ($result.FailedCount -gt 0) {
  throw "Refusing deploy: tests failed."
}

$files = @("RecklessTracker.lua", "RecklessTracker.toc")
foreach ($name in $files) {
  Copy-Item -LiteralPath (Join-Path $sourceDir $name) -Destination (Join-Path $LiveAddonDir $name) -Force
}

Get-FileHash -Algorithm SHA256 -LiteralPath @(
  (Join-Path $LiveAddonDir "RecklessTracker.lua"),
  (Join-Path $LiveAddonDir "RecklessTracker.toc")
) | Format-List Path, Hash
