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

if (Test-Path $rainmeter) {
    Start-Process $rainmeter
    Start-Sleep -Seconds 2
    & $rainmeter '!RefreshApp'
    Start-Sleep -Milliseconds 700

    $configs = @(
        'REOS\DisplayServices\OperatorWorkspace',
        'REOS\DisplayServices\HeaderAssembly',
        'REOS\DisplayServices\OperationsDirectory',
        'REOS\DisplayServices\SystemInstrumentation',
        'REOS\DisplayServices\SystemStatusBus',
        'REOS\Modules\OperationsTelemetry'
    )

    foreach ($config in $configs) {
        & $rainmeter '!ActivateConfig' $config
    }

    Write-Host 'REOS Display Services activated.' -ForegroundColor Green
}
else {
    Write-Warning 'Rainmeter was not detected. Install Rainmeter, refresh it, and load the REOS DisplayServices configurations manually.'
}

Write-Host ''
Write-Host 'The installer does not hide the Windows taskbar or desktop icons.'
Read-Host 'Press Enter to close'
