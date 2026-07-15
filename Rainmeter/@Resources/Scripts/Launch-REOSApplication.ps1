param(
    [Parameter(Mandatory)]
    [string]$ApplicationId,

    [switch]$NewSession
)

$ErrorActionPreference = 'SilentlyContinue'
$mapPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'Data\ApplicationMap.json'
if (-not (Test-Path $mapPath)) { exit 2 }

$map = Get-Content $mapPath -Raw | ConvertFrom-Json
$entry = $map.PSObject.Properties[$ApplicationId].Value
if (-not $entry) { exit 3 }

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class ReosLaunchApi {
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int command);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
'@

function Activate-ExistingProcess {
    param([string]$Executable)

    $processName = [IO.Path]::GetFileNameWithoutExtension($Executable)
    $candidate = Get-Process -Name $processName -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 } |
        Select-Object -First 1

    if (-not $candidate) { return $false }

    $handle = [IntPtr]$candidate.MainWindowHandle
    if ([ReosLaunchApi]::IsIconic($handle)) {
        [ReosLaunchApi]::ShowWindowAsync($handle, 9) | Out-Null
        Start-Sleep -Milliseconds 80
    }
    [ReosLaunchApi]::SetForegroundWindow($handle) | Out-Null
    return $true
}

foreach ($candidate in @($entry.Candidates)) {
    if (-not $NewSession -and (Activate-ExistingProcess -Executable $candidate)) {
        exit 0
    }

    $command = Get-Command $candidate -ErrorAction SilentlyContinue
    if (-not $command -and $candidate -notmatch '\.(msc|exe)$') { continue }

    $arguments = @($entry.Arguments)
    try {
        Start-Process -FilePath $candidate -ArgumentList $arguments
        exit 0
    }
    catch {
        continue
    }
}

exit 4
