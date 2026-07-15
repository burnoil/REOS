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

$stowageIni = Join-Path $target 'Modules\ApplicationStowage\ApplicationStowage.ini'
$stowageHelper = Join-Path $target '@Resources\Scripts\WindowState.ps1'

if (-not (Test-Path $stowageIni)) {
    throw "Application Stowage skin was not copied: $stowageIni"
}
if (-not (Test-Path $stowageHelper)) {
    throw "Application Stowage helper was not copied: $stowageHelper"
}

if (Test-Path $rainmeter) {
    Start-Process $rainmeter
    Start-Sleep -Seconds 2
    & $rainmeter '!RefreshApp'
    Start-Sleep -Milliseconds 900

    $configs = @(
        @{ Config = 'REOS\DisplayServices\OperatorWorkspace'; File = 'OperatorWorkspace.ini' },
        @{ Config = 'REOS\DisplayServices\HeaderAssembly'; File = 'HeaderAssembly.ini' },
        @{ Config = 'REOS\DisplayServices\OperationsDirectory'; File = 'OperationsDirectory.ini' },
        @{ Config = 'REOS\DisplayServices\SystemInstrumentation'; File = 'SystemInstrumentation.ini' },
        @{ Config = 'REOS\DisplayServices\SystemStatusBus'; File = 'SystemStatusBus.ini' },
        @{ Config = 'REOS\Modules\OperationsTelemetry'; File = 'OperationsTelemetry.ini' },
        @{ Config = 'REOS\Modules\ApplicationStowage'; File = 'ApplicationStowage.ini' }
    )

    foreach ($entry in $configs) {
        & $rainmeter '!ActivateConfig' $entry.Config $entry.File
        Start-Sleep -Milliseconds 150
    }

    & $rainmeter '!Refresh' 'REOS\Modules\ApplicationStowage'
    Write-Host 'REOS Display Services activated.' -ForegroundColor Green
    Write-Host 'Application Stowage activation was explicitly requested.' -ForegroundColor Green
}
else {
    Write-Warning 'Rainmeter was not detected. Install Rainmeter, refresh it, and load the REOS DisplayServices configurations manually.'
}

Write-Host ''
Write-Host 'The installer does not hide the Windows taskbar or desktop icons.'
Read-Host 'Press Enter to close'
