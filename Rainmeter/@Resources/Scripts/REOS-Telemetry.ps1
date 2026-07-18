param(
    [string]$ResourcePath,
    [int]$IntervalSeconds = 5
)

$ErrorActionPreference = 'SilentlyContinue'

if ([string]::IsNullOrWhiteSpace($ResourcePath)) {
    exit 2
}

$dataDirectory = Join-Path $ResourcePath 'Data'
$jsonPath = Join-Path $dataDirectory 'REOS-State.json'
$includePath = Join-Path $dataDirectory 'Telemetry.inc'
$lockPath = Join-Path $dataDirectory 'REOS-Telemetry.lock'

New-Item -ItemType Directory -Path $dataDirectory -Force | Out-Null

# Prevent duplicate collectors when Rainmeter is refreshed repeatedly.
if (Test-Path $lockPath) {
    $existingPid = Get-Content $lockPath -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existingPid -and (Get-Process -Id $existingPid -ErrorAction SilentlyContinue)) {
        exit 0
    }
}
$PID | Set-Content -Path $lockPath -Encoding ascii -Force

function Write-AtomicText {
    param([string]$Path, [string]$Content)
    $temporaryPath = "$Path.tmp"
    [System.IO.File]::WriteAllText($temporaryPath, $Content, [System.Text.UTF8Encoding]::new($false))
    Move-Item -Path $temporaryPath -Destination $Path -Force
}

try {
    while ($true) {
        $os = Get-CimInstance Win32_OperatingSystem
        $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
        $profile = Get-NetConnectionProfile | Where-Object { $_.IPv4Connectivity -ne 'Disconnected' } | Select-Object -First 1
        $ipConfig = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1

        $wlanText = netsh wlan show interfaces 2>$null
        $ssidLine = $wlanText | Select-String '^\s*SSID\s*:' | Select-Object -First 1
        $signalLine = $wlanText | Select-String '^\s*Signal\s*:' | Select-Object -First 1
        $ssid = if ($ssidLine) { $ssidLine.ToString().Split(':', 2)[1].Trim() } else { '' }
        $signal = if ($signalLine) { $signalLine.ToString().Split(':', 2)[1].Trim() } else { '--' }

        $totalBytes = [double]$os.TotalVisibleMemorySize * 1KB
        $freeBytes = [double]$os.FreePhysicalMemory * 1KB
        $usedBytes = [Math]::Max(0, $totalBytes - $freeBytes)
        $memoryPercent = if ($totalBytes -gt 0) { [Math]::Round(($usedBytes / $totalBytes) * 100) } else { 0 }
        $uptime = (Get-Date) - $os.LastBootUpTime

        $state = [ordered]@{
            schemaVersion = 1
            generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
            workstation = [ordered]@{
                cpuPercent = [int][Math]::Round($cpu.Average)
                memoryPercent = [int]$memoryPercent
                memoryUsedGB = [Math]::Round($usedBytes / 1GB, 1)
                memoryTotalGB = [Math]::Round($totalBytes / 1GB, 1)
                uptimeText = ('{0}:{1:00}:{2:00}:{3:00}' -f [int]$uptime.TotalDays, $uptime.Hours, $uptime.Minutes, $uptime.Seconds)
            }
            network = [ordered]@{
                name = if ($ssid) { $ssid } elseif ($profile.Name) { $profile.Name } else { 'LOCAL NETWORK' }
                interface = if ($ipConfig.InterfaceAlias) { $ipConfig.InterfaceAlias } else { 'UNKNOWN' }
                linkType = if ($ssid) { 'WI-FI' } elseif ($ipConfig.NetAdapter.MediaType) { 'ETHERNET' } else { 'UNKNOWN' }
                signal = $signal
                ipv4 = if ($ipConfig.IPv4Address.IPAddress) { $ipConfig.IPv4Address.IPAddress } else { '---.---.---.---' }
                gateway = if ($ipConfig.IPv4DefaultGateway.NextHop) { $ipConfig.IPv4DefaultGateway.NextHop } else { '---.---.---.---' }
                status = if ($ipConfig) { 'EXTERNAL COMMUNICATIONS AVAILABLE' } else { 'NETWORK LINK UNAVAILABLE' }
            }
        }

        Write-AtomicText -Path $jsonPath -Content ($state | ConvertTo-Json -Depth 5 -Compress)

        $include = @"
[Variables]
TelemetryGeneratedUtc=$($state.generatedUtc)
CPUPercent=$($state.workstation.cpuPercent)
MemoryPercent=$($state.workstation.memoryPercent)
MemoryUsedGB=$($state.workstation.memoryUsedGB)
MemoryTotalGB=$($state.workstation.memoryTotalGB)
UptimeText=$($state.workstation.uptimeText)
NetworkName=$($state.network.name)
InterfaceName=$($state.network.interface)
LinkType=$($state.network.linkType)
SignalText=$($state.network.signal)
IPv4Address=$($state.network.ipv4)
Gateway=$($state.network.gateway)
NetworkStatus=$($state.network.status)
"@
        Write-AtomicText -Path $includePath -Content $include
        Start-Sleep -Seconds ([Math]::Max(2, $IntervalSeconds))
    }
}
finally {
    Remove-Item $lockPath -Force -ErrorAction SilentlyContinue
}
