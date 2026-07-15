$ErrorActionPreference = 'SilentlyContinue'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class REOSWindowsShell {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string className, string windowName);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr handle, int command);
}
'@

$taskbar = [REOSWindowsShell]::FindWindow('Shell_TrayWnd', $null)
if ($taskbar -ne [IntPtr]::Zero) {
    [REOSWindowsShell]::ShowWindow($taskbar, 5) | Out-Null
}

$advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty -Path $advanced -Name HideIcons -Value 0

Stop-Process -Name explorer -Force
Start-Sleep -Milliseconds 500
Start-Process explorer.exe
