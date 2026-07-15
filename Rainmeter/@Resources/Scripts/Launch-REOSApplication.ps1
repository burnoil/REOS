param(
    [Parameter(Mandatory)]
    [string]$ApplicationId,

    [switch]$NewSession
)

$ErrorActionPreference = 'Stop'

$resourcesRoot = Split-Path -Parent $PSScriptRoot
$mapPath = Join-Path $resourcesRoot 'Data\ApplicationMap.json'
$stateDirectory = Join-Path $env:LOCALAPPDATA 'REOS'
$logPath = Join-Path $stateDirectory 'launcher.log'
New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null

function Write-LauncherLog {
    param([string]$Message)
    Add-Content -Path $logPath -Value "$(Get-Date -Format o) [$ApplicationId] $Message" -Encoding UTF8
}

try {
    if (-not (Test-Path -LiteralPath $mapPath)) {
        throw "Application map not found: $mapPath"
    }

    $map = Get-Content -LiteralPath $mapPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $property = $map.PSObject.Properties | Where-Object Name -EQ $ApplicationId | Select-Object -First 1
    if (-not $property) {
        throw "Application ID is not defined in the map."
    }

    $entry = $property.Value
    $arguments = @($entry.Arguments | ForEach-Object { [Environment]::ExpandEnvironmentVariables([string]$_) })

    foreach ($candidateValue in @($entry.Candidates)) {
        $candidate = [Environment]::ExpandEnvironmentVariables([string]$candidateValue)
        $resolvedPath = $null

        if ([IO.Path]::IsPathRooted($candidate) -and (Test-Path -LiteralPath $candidate)) {
            $resolvedPath = $candidate
        }
        else {
            $command = Get-Command -Name $candidate -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($command) {
                $resolvedPath = $command.Source
                if ([string]::IsNullOrWhiteSpace($resolvedPath)) {
                    $resolvedPath = $command.Path
                }
            }
        }

        if (-not $resolvedPath -and $candidate -match '\.msc$') {
            $resolvedPath = Join-Path $env:WINDIR 'System32\mmc.exe'
            $arguments = @($candidate)
        }

        if (-not $resolvedPath) {
            Write-LauncherLog "Candidate unavailable: $candidate"
            continue
        }

        Write-LauncherLog "Launching: $resolvedPath $($arguments -join ' ')"
        if ($arguments.Count -gt 0) {
            Start-Process -FilePath $resolvedPath -ArgumentList $arguments
        }
        else {
            Start-Process -FilePath $resolvedPath
        }
        exit 0
    }

    throw 'No configured launch candidate was available.'
}
catch {
    Write-LauncherLog "FAILED: $($_.Exception.Message)"
    exit 4
}
