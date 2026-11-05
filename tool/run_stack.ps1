# Starts the API (port 4000) and the admin site (port 3000). PostgreSQL runs as a Windows service.
#
#   powershell -ExecutionPolicy Bypass -File tool\run_stack.ps1          start
#   powershell -ExecutionPolicy Bypass -File tool\run_stack.ps1 -Seed    start and restore the demo student's data
#   powershell -ExecutionPolicy Bypass -File tool\run_stack.ps1 -Stop    stop the API and admin site
#
# Then run the student app with: flutter run -d windows
param([switch]$Seed, [switch]$Stop)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$api = Join-Path $root 'du_student_api'
$admin = Join-Path $root 'du_admin_web'
$logs = Join-Path $root '.stack-logs'

function Test-Port([int]$port) {
  $client = New-Object Net.Sockets.TcpClient
  try {
    $client.Connect('127.0.0.1', $port)
    return $true
  } catch {
    return $false
  } finally {
    $client.Close()
  }
}

function Wait-Port([int]$port, [string]$name, [int]$seconds = 90) {
  for ($i = 0; $i -lt $seconds; $i++) {
    if (Test-Port $port) { return }
    Start-Sleep -Seconds 1
  }
  throw "$name did not start on port $port. See $logs."
}

function Start-Hidden([string]$name, [string]$dir, [string]$command) {
  Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $command -WorkingDirectory $dir -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $logs "$name.log") -RedirectStandardError (Join-Path $logs "$name.err.log") | Out-Null
}

function Invoke-Pnpm([string]$dir, [string[]]$pnpmArgs) {
  Push-Location $dir
  try {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & pnpm @pnpmArgs 2>&1 | ForEach-Object { "$_" } | Select-Object -Last 2 | Out-Host
    $code = $LASTEXITCODE
    $ErrorActionPreference = $previous
    if ($code -ne 0) { throw "pnpm $($pnpmArgs -join ' ') failed" }
  } finally {
    Pop-Location
  }
}

if ($Stop) {
  Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
    Where-Object { $_.CommandLine -match 'du_student_app[\\/](du_student_api|du_admin_web)' -or $_.CommandLine -match 'pnpm\.cjs"\s+dev' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  'Stopped the API and admin site. PostgreSQL keeps running as a Windows service.'
  return
}

if (-not (Test-Path (Join-Path $api '.env'))) {
  throw 'du_student_api\.env is missing. Copy .env.example and set DATABASE_URL and the two JWT secrets.'
}
if (-not (Test-Port 5432)) {
  throw 'PostgreSQL is not running on port 5432. Start the postgresql-x64-17 service in Windows Services.'
}

New-Item -ItemType Directory -Force $logs | Out-Null

$adminEnv = Join-Path $admin '.env.local'
if (-not (Test-Path $adminEnv)) {
  'NEXT_PUBLIC_API_URL="http://localhost:4000"' | Set-Content -Path $adminEnv -Encoding ascii
  'Created du_admin_web\.env.local'
}

Invoke-Pnpm $api @('exec', 'prisma', 'migrate', 'deploy')
if ($Seed) { Invoke-Pnpm $api @('exec', 'prisma', 'db', 'seed') }

if (-not (Test-Port 4000)) {
  Start-Hidden 'api' $api 'pnpm dev'
  Wait-Port 4000 'The API'
}
if (-not (Test-Port 3000)) {
  Start-Hidden 'admin' $admin 'pnpm dev'
  Wait-Port 3000 'The admin site'
}

@'

Running:
  API          http://localhost:4000
  Admin site   http://localhost:3000   (admin / admin123)
  Student app  flutter run -d windows  (000 / student123)
'@
