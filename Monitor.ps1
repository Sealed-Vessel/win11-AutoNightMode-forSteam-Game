param([switch]$Check)
$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'NightLight.cs')
$stateDir = Join-Path $env:LOCALAPPDATA 'SteamNightLight'
if (-not $Check) { [IO.Directory]::CreateDirectory($stateDir) | Out-Null }
$pending = Join-Path $stateDir 'restore-pending'
$stop = Join-Path $stateDir 'stop'
$log = Join-Path $stateDir 'monitor.log'
function Log($text) {
    if ((Test-Path $log) -and (Get-Item $log).Length -gt 262144) { Move-Item $log "$log.old" -Force }
    Add-Content $log "$(Get-Date -Format s) $text"
}
function GameRunning {
    # Steam publishes an individual Running flag for each app, supporting multiple games.
    $base = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Software\Valve\Steam\Apps')
    if ($null -eq $base) { throw 'STEAM_MISSING' }
    try {
        foreach ($id in $base.GetSubKeyNames()) {
            if ($config.IgnoreAppIds -contains $id) { continue }
            $app = $base.OpenSubKey($id)
            try { if ($null -ne $app -and $app.GetValue('Running',0) -eq 1) { return $true } }
            finally { if ($null -ne $app) { $app.Dispose() } }
        }
        return $false
    } finally { $base.Dispose() }
}
$config = Get-Content (Join-Path $PSScriptRoot 'config.json') -Raw | ConvertFrom-Json
if ($Check) { Write-Output "NightLight=$([NightLight]::Get()); SteamGameRunning=$(GameRunning)"; return }
$mutex = New-Object Threading.Mutex($false, 'Local\SteamNightLightMonitor')
if (-not $mutex.WaitOne(0)) { $mutex.Dispose(); exit }
$lastError = ''
try {
    Log 'Monitor started.'
    while (-not (Test-Path $stop)) {
        try {
            if (GameRunning) {
                if (-not (Test-Path $pending)) { [IO.File]::WriteAllText($pending,'on') }
                if ([NightLight]::Get()) { [NightLight]::Set($false); Log 'Game active: Night Light off.' }
            } elseif (Test-Path $pending) {
                [NightLight]::Set($true)
                if (-not [NightLight]::Get()) { throw 'Night Light did not accept the on state.' }
                Remove-Item $pending
                Log 'All games exited: Night Light on.'
            }
            $lastError = ''
            Start-Sleep -Seconds 3
        } catch {
            if ($lastError -ne $_.Exception.Message) { Log $_.Exception.Message; $lastError = $_.Exception.Message }
            Start-Sleep -Seconds 15
        }
    }
} finally {
    if (Test-Path $pending) {
        try { [NightLight]::Set($true); Remove-Item $pending } catch { Log "Restore failed: $_" }
    }
    $mutex.ReleaseMutex(); $mutex.Dispose()
}
