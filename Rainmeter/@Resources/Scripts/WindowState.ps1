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

    [DllImport("user32.dll")]
    public static extern IntPtr GetWindow(IntPtr hWnd, uint command);

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
        Start-Sleep -Milliseconds 80
        [REOSWindowApi]::SetForegroundWindow($window) | Out-Null
    }
    exit
}

$shell = [REOSWindowApi]::GetShellWindow()
$windows = [System.Collections.Generic.List[object]]::new()

$callback = [REOSWindowApi+EnumWindowsProc]{
    param([IntPtr]$hWnd, [IntPtr]$lParam)

    if ($hWnd -eq $shell) { return $true }
    if (-not [REOSWindowApi]::IsWindowVisible($hWnd)) { return $true }
    if (-not [REOSWindowApi]::IsIconic($hWnd)) { return $true }

    # GW_OWNER = 4. Normal taskbar windows are generally unowned.
    if ([REOSWindowApi]::GetWindow($hWnd, 4) -ne [IntPtr]::Zero) { return $true }

    $length = [REOSWindowApi]::GetWindowTextLength($hWnd)
    if ($length -le 0) { return $true }

    $builder = [Text.StringBuilder]::new($length + 1)
    [void][REOSWindowApi]::GetWindowText($hWnd, $builder, $builder.Capacity)
    $title = $builder.ToString().Trim()
    if ([string]::IsNullOrWhiteSpace($title)) { return $true }

    # Avoid returning REOS support processes or shell surfaces.
    if ($title -match '^(Program Manager|Rainmeter|Windows Input Experience)$') { return $true }

    $safeTitle = $title -replace '[\r\n|]', ' '
    $windows.Add([pscustomobject]@{
        Handle = $hWnd.ToInt64()
        Title  = $safeTitle
    })

    return ($windows.Count -lt $Maximum)
}

[REOSWindowApi]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null

$slot = 1
foreach ($window in $windows) {
    '{0}|{1}|{2}' -f $slot, $window.Handle, $window.Title
    $slot++
}
