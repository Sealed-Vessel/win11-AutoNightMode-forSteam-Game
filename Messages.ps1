function Get-InstallErrorMessage([string]$Details) {
    if ($Details -match 'NIGHTLIGHT_MISSING') {
        return '缺少夜间模式数据：请在 Windows 设置中手动打开、关闭一次夜间模式，然后重新安装。 / Night Light data is missing: turn Night Light on and off in Windows Settings, then retry.'
    }
    if ($Details -match 'STEAM_MISSING') {
        return '缺少 Steam 游戏记录：请先打开 Steam，至少启动并退出过一次游戏，然后重新安装。 / Steam game records are missing: open Steam, start and exit a game once, then retry.'
    }
    return "安装失败 / Installation failed: $Details"
}
