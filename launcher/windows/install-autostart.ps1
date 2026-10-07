# Optional: run only when you want this widget to open at Windows sign-in.
# Uses the current user's Startup folder. Does not change execution policy.
$ErrorActionPreference = 'Stop'
$launcherPath = Join-Path $PSScriptRoot 'skincare-widget.bat'
if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    throw 'Widget launcher not found.'
}
$startupPath = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startupPath 'Skincare Widget.lnk'
if (Test-Path -LiteralPath $shortcutPath) {
    throw 'A Skincare Widget shortcut already exists. Review it before replacing it.'
}
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $launcherPath
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.WindowStyle = 7
$shortcut.Save()
Write-Output 'Auto-start shortcut created. Keep this folder in its current location.'
