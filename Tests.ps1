$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'NightLight.cs')
. (Join-Path $PSScriptRoot 'Messages.ps1')
[byte[]]$sample = 67,66,1,0,10,2,1,0,42,6,236,160,244,190,6,42,43,14,19,67,66,1,0,208,10,2,198,20,176,159,209,230,248,159,175,238,1,0,0,0,0
$old = $false
$on = [NightLight]::Transform($sample,$true,[ref]$old)
if ($old) { throw 'Off-state decoding failed' }
$off = [NightLight]::Transform($on,$false,[ref]$old)
if (-not $old) { throw 'On-state decoding failed' }
$same = [NightLight]::Transform($off,$false,[ref]$old)
if ($old -or [BitConverter]::ToString($same) -ne [BitConverter]::ToString($off)) { throw 'Idempotence failed' }
$sample[0] = 0
$rejected = $false
try { [NightLight]::Transform($sample,$true,[ref]$old) | Out-Null } catch { $rejected = $true }
if (-not $rejected) { throw 'Invalid format accepted' }
if ((Get-InstallErrorMessage 'STEAM_MISSING') -notmatch 'start and exit a game') { throw 'Steam hint missing' }
if ((Get-InstallErrorMessage 'NIGHTLIGHT_MISSING') -notmatch 'turn Night Light on and off') { throw 'Night Light hint missing' }
foreach ($errorText in @('Access denied','Unsupported Night Light format')) {
    if ((Get-InstallErrorMessage $errorText) -match 'then retry') { throw 'Unrelated error showed initialization hint' }
}
Get-ChildItem $PSScriptRoot -Filter *.ps1 | ForEach-Object {
    $tokens = $null; $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$parseErrors) | Out-Null
    if ($parseErrors) { throw $parseErrors }
}
$tempExe = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString() + '.exe')
try {
    Add-Type -Path (Join-Path $PSScriptRoot 'Launcher.cs') -OutputAssembly $tempExe -OutputType WindowsApplication
    $bytes = [IO.File]::ReadAllBytes($tempExe)
    $pe = [BitConverter]::ToInt32($bytes,60)
    if ([BitConverter]::ToUInt16($bytes,$pe+24+68) -ne 2) { throw 'Launcher is not a console-free GUI executable' }
} finally { if (Test-Path $tempExe) { Remove-Item $tempExe } }
Write-Host 'PASS: state codec, invalid format rejection, targeted error hints, script parsing, GUI launcher compilation.'
