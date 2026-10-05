$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Messages.ps1')
try {
    & (Join-Path $PSScriptRoot 'Monitor.ps1') -Check
    $dir = Join-Path $env:LOCALAPPDATA 'SteamNightLight'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $mutex = New-Object Threading.Mutex($false,'Local\SteamNightLightMonitor')
    if (-not $mutex.WaitOne(0)) { $mutex.Dispose(); throw 'Already running. Run Uninstall.cmd before reinstalling.' }
    $mutex.ReleaseMutex(); $mutex.Dispose()
    foreach ($name in @('Monitor.ps1','NightLight.cs','config.json','Uninstall.ps1')) {
        $dest = Join-Path $dir $name
        if ($name -eq 'config.json' -and (Test-Path $dest)) { continue }
        if ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot $name)) -ne $dest) { Copy-Item (Join-Path $PSScriptRoot $name) $dest -Force }
    }
    $launcher = Join-Path $dir 'SteamNightLight.exe'
    if (Test-Path $launcher) { Remove-Item $launcher }
    Add-Type -Path (Join-Path $PSScriptRoot 'Launcher.cs') -OutputAssembly $launcher -OutputType WindowsApplication
    Remove-Item (Join-Path $dir 'stop') -ErrorAction SilentlyContinue
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Startup')) 'SteamNightLight.lnk'))
    $link.TargetPath = $launcher
    $link.Arguments = ''
    $link.WindowStyle = 7
    $link.Save()
    Start-Process -FilePath $launcher -WindowStyle Hidden
    Write-Host '安装完成：已静默运行，开机登录后自动启动。 / Installed: running silently, starts automatically at sign-in.' -ForegroundColor Green
} catch { Write-Host (Get-InstallErrorMessage $_.Exception.ToString()) -ForegroundColor Red; exit 1 }
