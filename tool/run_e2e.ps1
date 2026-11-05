# Runs every check against the real stack: database, API, admin routes and the Windows app.
# Starts the stack if needed, and leaves the demo data as the seed defines it.
#
#   powershell -ExecutionPolicy Bypass -File tool\run_e2e.ps1 [-ShotDir C:\some\folder]
param([string]$ShotDir = '')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$failed = @()

function Reseed {
  Push-Location (Join-Path $root 'du_student_api')
  $ErrorActionPreference = 'Continue'
  & pnpm exec prisma db seed 2>&1 | ForEach-Object { "$_" } | Select-Object -Last 1 | Out-Host
  $ErrorActionPreference = 'Stop'
  Pop-Location
}

function Run([string]$name, [string[]]$flutterArgs) {
  "=== $name"
  $ErrorActionPreference = 'Continue'
  & flutter @flutterArgs 2>&1 | ForEach-Object { "$_" } | Select-String -Pattern '\[E\]$|All tests passed|Some tests failed|Expected:|Actual:|Timed out|Which:|EXCEPTION CAUGHT|should ' | ForEach-Object { $_.Line } | Select-Object -Last 25 | Out-Host
  $code = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  if ($code -ne 0) { $script:failed += $name }
}

# Started on its own, because the servers it launches stay running and would hold a pipe open forever.
$stackLog = Join-Path $env:TEMP 'du_run_stack.log'
$stack = Start-Process powershell -ArgumentList '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'run_stack.ps1'), '-Seed' -WindowStyle Hidden -RedirectStandardOutput $stackLog -PassThru
$stack.WaitForExit()
Get-Content $stackLog -Tail 5

$define = @()
if ($ShotDir) {
  New-Item -ItemType Directory -Force $ShotDir | Out-Null
  $define = @("--dart-define=E2E_SHOT_DIR=$ShotDir")
}

$env:LIVE_API_URL = 'http://localhost:4000'
Run 'Analyze' @('analyze')
Run 'Unit, widget, golden and live API tests' @('test')
Run 'Real app: student walkthrough' (@('test', 'integration_test/live_app_test.dart', '-d', 'windows') + $define)
Reseed
Run 'Real app: admin changes reach the app' (@('test', 'integration_test/admin_to_app_test.dart', '-d', 'windows') + $define)
Reseed
Run 'Real app: two students, separate data' (@('test', 'integration_test/two_students_test.dart', '-d', 'windows') + $define)
Reseed
Run 'Real app: log in, then close' (@('test', 'integration_test/stay_logged_in_1_test.dart', '-d', 'windows') + $define)
Run 'Real app: reopen, still logged in' (@('test', 'integration_test/stay_logged_in_2_test.dart', '-d', 'windows') + $define)

''
if ($failed.Count) {
  "FAILED: $($failed -join ', ')"
  exit 1
}
'All checks passed.'
