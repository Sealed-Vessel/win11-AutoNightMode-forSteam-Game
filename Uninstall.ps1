$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:LOCALAPPDATA 'SteamNightLight'
$link = Join-Path ([Environment]::GetFolderPath('Startup')) 'SteamNightLight.lnk'
if (Test-Path $link) { Remove-Item $link }
if (Test-Path $dir) { [IO.File]::WriteAllText((Join-Path $dir 'stop'),'stop') }
Write-Host '已取消自启动，程序约 20 秒内停止，按需恢复夜间模式。 / Autostart removed. Stops within about 20 seconds and restores Night Light if needed.'
Write-Host "程序与日志保留于 / Files and logs retained in: $dir"
