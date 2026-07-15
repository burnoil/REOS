$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class REOSWindowTraceApi
{
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    public struct WINDOWPLACEMENT
    {
        public int length;
        public int flags;
        public int showCmd;
        public System.Drawing.Point ptMinPosition;
        public System.Drawing.Point ptMaxPosition;
        public System.Drawing.Rectangle rcNormalPosition;
    }

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
    public static extern IntPtr GetWindow(IntPtr hWnd, uint command);

    [DllImport("user32.dll")]
    public static extern IntPtr GetAncestor(IntPtr hWnd, uint flags);

    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int index);

    [DllImport("user32.dll")]
    public static extern bool GetWindowPlacement(IntPtr hWnd, ref WINDOWPLACEMENT placement);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("dwmapi.dll")]
    public static extern int DwmGetWindowAttribute(IntPtr hWnd, int attribute, out int value, int size);
}
'@ -ReferencedAssemblies System.Drawing

$rows = [System.Collections.Generic.List[object]]::new()
$callback = [REOSWindowTraceApi+EnumWindowsProc]{
    param([IntPtr]$hWnd, [IntPtr]$lParam)

    $length = [REOSWindowTraceApi]::GetWindowTextLength($hWnd)
    if ($length -le 0) { return $true }

    $builder = [Text.StringBuilder]::new($length + 1)
    [void][REOSWindowTraceApi]::GetWindowText($hWnd, $builder, $builder.Capacity)
    $title = $builder.ToString().Trim()
    if ([string]::IsNullOrWhiteSpace($title)) { return $true }

    [uint32]$processId = 0
    [void][REOSWindowTraceApi]::GetWindowThreadProcessId($hWnd, [ref]$processId)
    $processName = try { (Get-Process -Id $processId -ErrorAction Stop).ProcessName } catch { '<unknown>' }

    $placement = New-Object REOSWindowTraceApi+WINDOWPLACEMENT
    $placement.length = [Runtime.InteropServices.Marshal]::SizeOf($placement)
    [void][REOSWindowTraceApi]::GetWindowPlacement($hWnd, [ref]$placement)

    $cloaked = 0
    try { [void][REOSWindowTraceApi]::DwmGetWindowAttribute($hWnd, 14, [ref]$cloaked, 4) } catch {}

    $exStyle = [REOSWindowTraceApi]::GetWindowLong($hWnd, -20)
    $owner = [REOSWindowTraceApi]::GetWindow($hWnd, 4).ToInt64()
    $rootOwner = [REOSWindowTraceApi]::GetAncestor($hWnd, 3).ToInt64()

    $rows.Add([pscustomobject]@{
        Process     = $processName
        PID         = $processId
        Handle      = $hWnd.ToInt64()
        Visible     = [REOSWindowTraceApi]::IsWindowVisible($hWnd)
        IsIconic    = [REOSWindowTraceApi]::IsIconic($hWnd)
        ShowCmd     = $placement.showCmd
        Cloaked     = $cloaked
        Owner       = $owner
        RootOwner   = $rootOwner
        ToolWindow  = (($exStyle -band 0x80) -ne 0)
        AppWindow   = (($exStyle -band 0x40000) -ne 0)
        Title       = $title
    })

    return $true
}

[void][REOSWindowTraceApi]::EnumWindows($callback, [IntPtr]::Zero)

$outFile = Join-Path $PSScriptRoot 'WindowStateTrace.csv'
$rows |
    Sort-Object Process, Title |
    Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8

Write-Host ''
Write-Host 'REOS WINDOW STATE TRACE' -ForegroundColor Cyan
Write-Host ''
Write-Host "Wrote $($rows.Count) titled top-level windows to:"
Write-Host $outFile -ForegroundColor Green
Write-Host ''
Write-Host 'With Edge, Terminal/PowerShell, and Notepad++ minimized, run this script once.'
Write-Host 'Then send the CSV or paste the rows for those processes.'
Write-Host ''
$rows |
    Where-Object { $_.Process -match 'msedge|WindowsTerminal|pwsh|powershell|notepad\+\+' } |
    Format-Table Process,PID,Handle,Visible,IsIconic,ShowCmd,Cloaked,Owner,RootOwner,ToolWindow,AppWindow,Title -AutoSize
