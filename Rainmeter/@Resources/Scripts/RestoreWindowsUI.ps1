$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class REOSNative {
    [StructLayout(LayoutKind.Sequential)]
    public struct APPBARDATA {
        public uint cbSize;
        public IntPtr hWnd;
        public uint uCallbackMessage;
        public uint uEdge;
        public RECT rc;
        public IntPtr lParam;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int left;
        public int top;
        public int right;
        public int bottom;
    }

    [DllImport("shell32.dll")]
    public static extern UIntPtr SHAppBarMessage(uint dwMessage, ref APPBARDATA pData);

    [DllImport("user32.dll", SetLastError=true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError=true)]
    public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr childAfter, string className, string windowName);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
}
'@

function Get-DesktopView {
    $progman = [REOSNative]::FindWindow('Progman', $null)
    $view = [REOSNative]::FindWindowEx($progman, [IntPtr]::Zero, 'SHELLDLL_DefView', $null)
    if ($view -ne [IntPtr]::Zero) { return $view }

    $worker = [IntPtr]::Zero
    do {
        $worker = [REOSNative]::FindWindowEx([IntPtr]::Zero, $worker, 'WorkerW', $null)
        if ($worker -eq [IntPtr]::Zero) { break }
        $view = [REOSNative]::FindWindowEx($worker, [IntPtr]::Zero, 'SHELLDLL_DefView', $null)
        if ($view -ne [IntPtr]::Zero) { return $view }
    } while ($true)

    return [IntPtr]::Zero
}

# Restore the normal taskbar state without terminating Explorer.
$abd = New-Object REOSNative+APPBARDATA
$abd.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($abd)
$abd.lParam = [IntPtr]2 # ABS_ALWAYSONTOP
[void][REOSNative]::SHAppBarMessage(0x0000000A, [ref]$abd) # ABM_SETSTATE

# Restore desktop icons only when they are currently hidden.
$advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty -Path $advanced -Name HideIcons -Type DWord -Value 0
$desktopView = Get-DesktopView
if ($desktopView -ne [IntPtr]::Zero -and -not [REOSNative]::IsWindowVisible($desktopView)) {
    [void][REOSNative]::SendMessage($desktopView, 0x0111, [IntPtr]0x7402, [IntPtr]::Zero)
}

exit 0
