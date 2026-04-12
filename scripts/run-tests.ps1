Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$testPath = Join-Path $repoRoot "tests\RecklessTracker.Tests.ps1"

if (-not (Get-Module -ListAvailable Pester)) {
  throw "Pester module not found. Install Pester to run tests."
}


# Import the newest installed Pester version so local and CI runs behave consistently.
$pesterModule = Get-Module -ListAvailable Pester |
  Sort-Object Version -Descending |
  Select-Object -First 1

Import-Module Pester -RequiredVersion $pesterModule.Version -Force

if ((Get-Module Pester).Version.Major -ge 5) {
  $config = New-PesterConfiguration
  $config.Run.Path = $testPath
  $config.Run.PassThru = $true
  $config.Output.Verbosity = "Detailed"

  $result = Invoke-Pester -Configuration $config
  if (($result.FailedCount -gt 0) -or ($result.Result -ne "Passed")) {
    exit 1
  }
} else {
  $result = Invoke-Pester -Script $testPath -PassThru
  if ($result.FailedCount -gt 0) {
    exit 1
  }
}
