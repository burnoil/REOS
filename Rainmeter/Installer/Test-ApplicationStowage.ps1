$ErrorActionPreference = 'Continue'

$skinRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins\REOS'
$rainmeter = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'
$skin = Join-Path $skinRoot 'Modules\ApplicationStowage\ApplicationStowage.ini'
$helper = Join-Path $skinRoot '@Resources\Scripts\WindowState.ps1'

Write-Host ''
Write-Host 'REOS APPLICATION STOWAGE DIAGNOSTIC' -ForegroundColor Cyan
Write-Host ''

Write-Host "Skin file:   $skin"
Write-Host "Exists:      $(Test-Path $skin)"
Write-Host "Helper file: $helper"
Write-Host "Exists:      $(Test-Path $helper)"
Write-Host "Rainmeter:   $rainmeter"
Write-Host "Exists:      $(Test-Path $rainmeter)"
Write-Host ''

if (Test-Path $helper) {
    Write-Host 'Current minimized-window helper output:' -ForegroundColor Yellow
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $helper -Mode List -Maximum 6
    Write-Host ''
}

if ((Test-Path $rainmeter) -and (Test-Path $skin)) {
    Write-Host 'Activating exact Rainmeter configuration and skin file...' -ForegroundColor Yellow
    & $rainmeter '!DeactivateConfig' 'REOS\Modules\ApplicationStowage'
    Start-Sleep -Milliseconds 300
    & $rainmeter '!ActivateConfig' 'REOS\Modules\ApplicationStowage' 'ApplicationStowage.ini'
    Start-Sleep -Milliseconds 800
    & $rainmeter '!Move' 330 880 'REOS\Modules\ApplicationStowage'
    & $rainmeter '!ZPos' -1 'REOS\Modules\ApplicationStowage'
    & $rainmeter '!Refresh' 'REOS\Modules\ApplicationStowage'
    Write-Host 'Activation commands sent.' -ForegroundColor Green
}

Write-Host ''
Write-Host 'Open Rainmeter > About > Log if the panel still does not appear.'
Read-Host 'Press Enter to close'
