# 오늘의 스킨케어 위젯 런처 (Windows)
# 크롬 앱 창으로 열고, 화면 오른쪽 위에 붙이고, 항상 위에 고정합니다.

# ---- 설정 (필요하면 값만 바꾸세요) ----
$Url         = ''         # 비워 두면 이 저장소의 index.html을 엽니다. GitHub Pages 주소를 넣어도 돼요.
$TitleMatch  = '스킨케어'  # CONFIG.title에 들어 있는 단어 (창을 찾을 때 사용)
$Width       = 420        # 위젯 가로 크기
$Height      = 900        # 위젯 세로 크기 (화면보다 크면 자동으로 줄어듦)
$Margin      = 16         # 화면 가장자리와의 간격
$AlwaysOnTop = $true      # 항상 위에 두지 않으려면 $false
# ----------------------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class SkinWin {
    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int w, int h, uint flags);
}
"@

function Get-ChromeWindows {
    $script:chromeIds = @(Get-Process -Name chrome -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
    $script:found = New-Object System.Collections.ArrayList
    $callback = [SkinWin+EnumProc]{
        param([IntPtr]$hWnd, [IntPtr]$lParam)
        if ([SkinWin]::IsWindowVisible($hWnd)) {
            $procId = [uint32]0
            [void][SkinWin]::GetWindowThreadProcessId($hWnd, [ref]$procId)
            if ($script:chromeIds -contains $procId) {
                $sb = New-Object System.Text.StringBuilder 512
                [void][SkinWin]::GetWindowText($hWnd, $sb, 512)
                if ($sb.Length -gt 0) {
                    [void]$script:found.Add([pscustomobject]@{ Handle = $hWnd; Title = $sb.ToString() })
                }
            }
        }
        return $true
    }
    [void][SkinWin]::EnumWindows($callback, [IntPtr]::Zero)
    return $script:found
}

# 크롬 위치 찾기
$chrome = 'chrome.exe'
foreach ($p in @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")) {
    if (Test-Path $p) { $chrome = $p; break }
}

# 열 주소 정하기
if ([string]::IsNullOrWhiteSpace($Url)) {
    $repo  = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $index = Join-Path $repo 'index.html'
    if (-not (Test-Path $index)) { $index = Join-Path $PSScriptRoot 'index.html' }
    if (-not (Test-Path $index)) { return }
    $Url = ([System.Uri](Resolve-Path $index).Path).AbsoluteUri
}

# 실행 전 창 목록을 기억해 두고, 새로 생긴 창을 위젯으로 인식
$before = @(Get-ChromeWindows | ForEach-Object { $_.Handle })
Start-Process -FilePath $chrome -ArgumentList "--app=$Url"

$target = $null
for ($i = 0; $i -lt 40 -and -not $target; $i++) {
    Start-Sleep -Milliseconds 500
    $new = @(Get-ChromeWindows | Where-Object { $before -notcontains $_.Handle })
    $target = $new | Where-Object { $_.Title -like "*$TitleMatch*" } | Select-Object -First 1
    if (-not $target -and $i -ge 10 -and $new.Count -eq 1) { $target = $new[0] }
}
if (-not $target) { return }

# 화면 오른쪽 위에 배치
$area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$w = [Math]::Min($Width,  $area.Width  - $Margin * 2)
$h = [Math]::Min($Height, $area.Height - $Margin * 2)
$x = $area.Right - $w - $Margin
$y = $area.Top + $Margin

$HWND_TOPMOST   = [IntPtr](-1)
$SWP_NOZORDER   = 0x0004
$SWP_SHOWWINDOW = 0x0040

function Place {
    if ($AlwaysOnTop) {
        [void][SkinWin]::SetWindowPos($target.Handle, $HWND_TOPMOST, $x, $y, $w, $h, $SWP_SHOWWINDOW)
    } else {
        [void][SkinWin]::SetWindowPos($target.Handle, [IntPtr]::Zero, $x, $y, $w, $h, ($SWP_SHOWWINDOW -bor $SWP_NOZORDER))
    }
}

Place
Start-Sleep -Milliseconds 1500
Place   # 크롬이 창 크기를 되돌리는 경우를 대비해 한 번 더
