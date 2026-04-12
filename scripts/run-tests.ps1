Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$testPath = Join-Path $repoRoot "tests\RecklessTracker.Tests.ps1"

if (-not (Get-Module -ListAvailable Pester)) {
  throw "Pester module not found. Install Pester to run tests."
}

$result = Invoke-Pester -Script $testPath -PassThru
if ($result.FailedCount -gt 0) {
  exit 1
}
