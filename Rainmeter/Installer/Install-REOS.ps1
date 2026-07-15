$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$source = Join-Path $repositoryRoot 'Rainmeter'
$target = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins\REOS'
$rainmeter = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'

Write-Host ''
Write-Host 'ROCKWELL ENGINEERING OPERATIONS SYSTEM' -ForegroundColor Cyan
Write-Host 'REOS Display Services installation' -ForegroundColor Cyan
Write-Host ''

if (Test-Path $target) {
    $backup = "$target.backup.$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $target $backup -Recurse -Force
    Write-Host "Existing installation backed up to $backup"
    Remove-Item $target -Recurse -Force
}

New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item (Join-Path $source '*') $target -Recurse -Force
Write-Host "Installed REOS to $target"

$workspaceIni = Join-Path $target 'DisplayServices\OperatorWorkspace\OperatorWorkspace.ini'
$stowageCards = Join-Path $target '@Resources\Scripts\StowageCards.lua'
$restoreHelper = Join-Path $target '@Resources\Scripts\Restore-StowedApplication.ps1'

if (-not (Test-Path $workspaceIni)) {
    throw "Operator Workspace skin was not copied: $workspaceIni"
}
if (-not (Test-Path $stowageCards)) {
    throw "Embedded Stowage renderer was not copied: $stowageCards"
}
if (-not (Test-Path $restoreHelper)) {
    throw "Stowage restore helper was not copied: $restoreHelper"
}

if (Test-Path $rainmeter) {
    Start-Process $rainmeter
    Start-Sleep -Seconds 2
    & $rainmeter '!RefreshApp'
    Start-Sleep -Milliseconds 900

    # WO-005 rationalization: these former floating modules are now retired.
    & $rainmeter '!DeactivateConfig' 'REOS\Modules\OperationsTelemetry'
    & $rainmeter '!DeactivateConfig' 'REOS\Modules\ApplicationStowage'

    $configs = @(
        @{ Config = 'REOS\DisplayServices\OperatorWorkspace'; File = 'OperatorWorkspace.ini' },
        @{ Config = 'REOS\DisplayServices\HeaderAssembly'; File = 'HeaderAssembly.ini' },
        @{ Config = 'REOS\DisplayServices\OperationsDirectory'; File = 'OperationsDirectory.ini' },
        @{ Config = 'REOS\DisplayServices\SystemInstrumentation'; File = 'SystemInstrumentation.ini' },
        @{ Config = 'REOS\DisplayServices\SystemStatusBus'; File = 'SystemStatusBus.ini' }
    )

    foreach ($entry in $configs) {
        & $rainmeter '!ActivateConfig' $entry.Config $entry.File
        Start-Sleep -Milliseconds 150
    }

    & $rainmeter '!Refresh' 'REOS\DisplayServices\OperatorWorkspace'
    Write-Host 'REOS Display Services activated.' -ForegroundColor Green
    Write-Host 'Application Stowage is now embedded in Operator Workspace.' -ForegroundColor Green
    Write-Host 'Legacy floating modules deactivated.' -ForegroundColor Green
}
else {
    Write-Warning 'Rainmeter was not detected. Install Rainmeter, refresh it, and load the REOS DisplayServices configurations manually.'
}

Write-Host ''
Write-Host 'The installer does not hide the Windows taskbar or desktop icons.'
Read-Host 'Press Enter to close'
