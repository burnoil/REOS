# WO-011 — REOS v0.3 Prototype Test

## Purpose

Validate the first responsive industrial-console modules without replacing or disabling the current REOS build.

## Included prototype modules

- `DisplayServices/HeaderAssemblyV03.ini`
- `Modules/WorkstationHealth/WorkstationHealthV03.ini`
- `Modules/EngineeringNetwork/EngineeringNetworkV03.ini`
- `Prototype/V03Controller.ini`

## Installation

Copy the repository `Rainmeter` directory into the installed REOS skin directory so the resulting path is similar to:

```text
Documents\Rainmeter\Skins\REOS\
```

Refresh Rainmeter.

## Launch

Load:

```text
REOS\Prototype\V03Controller.ini
```

The controller activates and positions the three prototype modules, then unloads itself. It does not unload the existing REOS modules.

## Validation checklist

### Header

- Fits entirely inside the active Windows work area.
- Uses the Compact profile on a 3:2 Surface display.
- Uses the Wide profile on a 16:9 desktop display.
- Facility, operator, console, and session fields remain readable.
- No header field overlaps another field.

### Workstation Health

- CPU bar and percentage update.
- Physical-memory bar and percentage update.
- Uptime displays in days:hours:minutes:seconds.
- Module width matches the systems rail.

### Engineering Network

- Wi-Fi displays the connected SSID as `FACILITY NETWORK`.
- Ethernet displays the active Windows connection profile or `LOCAL NETWORK`.
- Active interface, link type, IPv4 address, and gateway populate.
- A disconnected or unavailable field fails safely instead of breaking the skin.

## Known limitations

- The authentic Rockwell logo asset is not yet wired into the installed package.
- Network telemetry temporarily uses a hidden PowerShell RunCommand measure. REOS.Core will own this data later.
- Only the header and first two right-rail modules are included.
- The prototype has not yet been verified on every Windows DPI configuration.

## Rollback

Unload these configurations from Rainmeter:

```text
REOS\DisplayServices
REOS\Modules\WorkstationHealth
REOS\Modules\EngineeringNetwork
```

The existing REOS console remains available throughout the test.
