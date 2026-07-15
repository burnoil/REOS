param(
    [ValidateSet('List','Restore')]
    [string]$Mode = 'List',

    [Int64]$Handle = 0,

    [int]$Maximum = 6
)

$ErrorActionPreference = 'SilentlyContinue'

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class REOSWindowApi
{
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);

    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetShellWindow();

    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtr")]
    public static extern IntPtr GetWindowLongPtr64(IntPtr hWnd, int index);

    [DllImport("user32.dll", EntryPoint = "GetWindowLong")]
    public static extern IntPtr GetWindowLongPtr32(IntPtr hWnd, int index);

    public static IntPtr GetWindowLongPtr(IntPtr hWnd, int index)
    {
        return IntPtr.Size == 8 ? GetWindowLongPtr64(hWnd, index) : GetWindowLongPtr32(hWnd, index);
    }

    [DllImport("dwmapi.dll")]
    public static extern int DwmGetWindowAttribute(IntPtr hWnd, int attribute, out int value, int size);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int command);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
'@

if ($Mode -eq 'Restore') {
    if ($Handle -gt 0) {
        $window = [IntPtr]$Handle
        [REOSWindowApi]::ShowWindowAsync($window, 9) | Out-Null
        Start-Sleep -Milliseconds 100
        [REOSWindowApi]::SetForegroundWindow($window) | Out-Null
    }
    exit
}

$shell = [REOSWindowApi]::GetShellWindow()
$windows = [System.Collections.Generic.List[object]]::new()
$seen = [System.Collections.Generic.HashSet[long]]::new()

$GWL_EXSTYLE = -20
$WS_EX_TOOLWINDOW = 0x00000080
$DWMWA_CLOAKED = 14

$callback = [REOSWindowApi+EnumWindowsProc]{
    param([IntPtr]$hWnd, [IntPtr]$lParam)

    if ($hWnd -eq $shell) { return $true }
    if (-not [REOSWindowApi]::IsWindowVisible($hWnd)) { return $true }
    if (-not [REOSWindowApi]::IsIconic($hWnd)) { return $true }

    # Exclude utility/tool windows rather than excluding every owned window.
    # Chromium and Windows Terminal can use owned top-level windows and were
    # incorrectly removed by the previous GW_OWNER test.
    $extendedStyle = [REOSWindowApi]::GetWindowLongPtr($hWnd, $GWL_EXSTYLE).ToInt64()
    if (($extendedStyle -band $WS_EX_TOOLWINDOW) -ne 0) { return $true }

    $cloaked = 0
    [void][REOSWindowApi]::DwmGetWindowAttribute($hWnd, $DWMWA_CLOAKED, [ref]$cloaked, 4)
    if ($cloaked -ne 0) { return $true }

    $length = [REOSWindowApi]::GetWindowTextLength($hWnd)
    if ($length -le 0) { return $true }

    $builder = [Text.StringBuilder]::new($length + 1)
    [void][REOSWindowApi]::GetWindowText($hWnd, $builder, $builder.Capacity)
    $title = $builder.ToString().Trim()
    if ([string]::IsNullOrWhiteSpace($title)) { return $true }

    if ($title -match '^(Program Manager|Rainmeter|Windows Input Experience|Settings)$') { return $true }

    [uint32]$processId = 0
    [void][REOSWindowApi]::GetWindowThreadProcessId($hWnd, [ref]$processId)
    $processName = ''
    if ($processId -gt 0) {
        $processName = (Get-Process -Id $processId -ErrorAction SilentlyContinue).ProcessName
    }

    $handleValue = $hWnd.ToInt64()
    if (-not $seen.Add($handleValue)) { return $true }

    $safeTitle = $title -replace '[\r\n|]', ' '
    $safeProcess = ($processName -replace '[\r\n|]', ' ').Trim()

    $windows.Add([pscustomobject]@{
        Handle  = $handleValue
        Process = $safeProcess
        Title   = $safeTitle
    })

    return ($windows.Count -lt $Maximum)
}

[REOSWindowApi]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null

$slot = 1
foreach ($window in $windows) {
    '{0}|{1}|{2}|{3}' -f $slot, $window.Handle, $window.Process, $window.Title
    $slot++
}
