param(
    [Parameter(Mandatory)]
    [long]$Handle
)

$ErrorActionPreference = 'SilentlyContinue'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class ReosRestoreApi {
    [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int command);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
'@

$window = [IntPtr]$Handle
[ReosRestoreApi]::ShowWindowAsync($window, 9) | Out-Null
Start-Sleep -Milliseconds 100
[ReosRestoreApi]::SetForegroundWindow($window) | Out-Null
