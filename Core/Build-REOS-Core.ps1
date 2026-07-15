$ErrorActionPreference = 'Stop'

$project = Join-Path $PSScriptRoot 'REOS.Core\REOS.Core.csproj'
$output = Join-Path $PSScriptRoot 'Build\win-x64'

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw '.NET 8 SDK was not found. Install the .NET 8 SDK, then run this script again.'
}

Write-Host ''
Write-Host 'REOS.CORE BUILD' -ForegroundColor Cyan
Write-Host ''

dotnet publish $project `
    --configuration Release `
    --runtime win-x64 `
    --self-contained false `
    --output $output

if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish failed with exit code $LASTEXITCODE"
}

Write-Host ''
Write-Host "Build complete: $output" -ForegroundColor Green
Write-Host 'Run REOS.Core.exe from that directory.'
