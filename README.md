# Steam Night Light

Steam 游戏运行时关闭 Windows 夜间模式，全部游戏退出后打开。后台静默运行，无托盘图标、弹窗或联网。

Turn Windows Night Light off while Steam games are running, and on after all games exit. Runs silently without a tray icon, popups, or network access.

## 中文

- **安装：** 下载并解压，双击 `Install.cmd`，无需管理员权限或额外依赖。安装成功立即运行，并在以后开机登录当前账户时静默自启。只有安装/卸载时显示命令窗口。
- **检查：** 安装自动检查 Steam 和夜间模式数据，仅在缺少对应数据时提示初始化步骤；权限、格式等错误显示实际错误。
- **卸载：** 双击 `Uninstall.cmd`，取消自启动，约 20 秒内停止。程序和日志保留在 `%LOCALAPPDATA%\SteamNightLight`，停止后可自行删除。
- **行为：** 每 3 秒检查 Steam；所有游戏退出并稳定 10 秒后打开夜间模式，即使游戏前原本关闭。无游戏状态变化时不干预手动开关。保留暖色强度和 Windows 定时设置。
- **排除：** 编辑安装目录里的 `config.json`，向 `IgnoreAppIds` 添加 Steam App ID 字符串；默认忽略 Wallpaper Engine（431960）。卸载停止后重装以重启，已有配置会保留。
- **诊断：** 安装目录的 `monitor.log` 记录运行错误，`launcher.log` 记录启动错误。后台错误只记日志，不弹窗。Steam 状态残留、常驻启动器或非 Steam 游戏可能影响识别。

面向 Windows 11 24H2/25H2 的特定 CloudStore 数据格式；不兼容格式拒绝写入。强制结束程序时不能立即恢复，下次启动会处理待恢复标记。首次安装请实际启动、退出游戏验证屏幕变化。已完成离线测试，尚未完成真实桌面和登录自启验证。

## English

- **Install:** Extract and double-click `Install.cmd`. No administrator rights or extra dependencies. Starts immediately and silently at future sign-ins for the current user. Only installation/uninstallation shows a console.
- **Checks:** Installation checks Steam and Night Light data. Initialization instructions appear only when the corresponding data is missing; other errors show their actual details.
- **Uninstall:** Double-click `Uninstall.cmd`. Removes autostart and stops within about 20 seconds. Files/logs remain in `%LOCALAPPDATA%\SteamNightLight`; delete them after it stops if desired.
- **Behavior:** Polls every 3 seconds. Enables Night Light after all games have been absent for 10 seconds, even if it was off before gaming. Leaves idle manual changes alone. Preserves color temperature and Windows scheduling.
- **Exclusions:** Edit installed `config.json`; add Steam App ID strings to `IgnoreAppIds`. Wallpaper Engine (431960) is excluded by default. Uninstall, wait for shutdown, and reinstall to restart; existing configuration is preserved.
- **Diagnostics:** See installed `monitor.log` and `launcher.log`. Background errors are logged without popups. Stale Steam flags, persistent launchers and non-Steam games can affect detection.

Targets a specific Windows 11 24H2/25H2 CloudStore format; unknown formats are rejected. Forced termination cannot restore immediately; the next launch handles pending recovery. Verify actual display changes with a game after installation. Offline tests pass; actual desktop behavior and sign-in startup have not been verified.

## Development / 开发

Windows PowerShell 5.1 is built into Windows. The installer compiles `Launcher.cs` as a GUI executable, which starts PowerShell without creating a console. A per-user Startup shortcut launches it at sign-in. `Monitor.ps1` uses a mutex to prevent duplicate monitors; `NightLight.cs` changes only the Night Light state. Execution-policy bypass applies only to the launched processes.

Windows 内置 PowerShell 5.1；安装时将 `Launcher.cs` 编译为无控制台启动器，通过当前用户启动文件夹实现登录自启，互斥锁避免重复运行。执行策略绕过仅作用于启动的进程。

Run offline tests / 运行离线测试：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Tests.ps1
```

Format reference / 格式参考：[win-nightlight-cli](https://github.com/kvnxiao/win-nightlight-cli/blob/main/docs/nightlight-registry-format.md). Windows does not publicly document this format / 此格式不是 Windows 公开接口。
