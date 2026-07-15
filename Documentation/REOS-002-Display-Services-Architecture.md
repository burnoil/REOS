# REOS-002

## Display Services Architecture

**Revision:** A  
**Status:** Development baseline

## 1. Scope

REOS Display Services is the Rainmeter implementation layer that frames the Windows operator workspace and presents persistent Rockwell engineering information.

## 2. System layers

```text
Windows
  └─ Rainmeter
      └─ REOS Display Services
          ├─ Header Assembly
          ├─ Operations Directory
          ├─ Operator Workspace Frame
          ├─ System Instrumentation
          ├─ System Status Bus
          └─ Optional Display Modules
```

Windows remains fully available and recoverable. REOS does not replace the Windows shell.

## 3. Permanent assemblies

### 3.1 Header Assembly

Displays Rockwell identity, facility, workstation, operator, access class, date, and time.

### 3.2 Operations Directory

Provides stable access to engineering applications and Windows functions using REOS terminology.

### 3.3 Operator Workspace Frame

Defines the central engineering work area. It shall remain visually quiet and shall not obstruct normal application use.

### 3.4 System Instrumentation

Displays workstation health, network telemetry, storage state, and engineering archive information.

### 3.5 System Status Bus

Presents compact persistent state for communications, power, data services, storage, security, environment, and message traffic.

## 4. Repository mapping

```text
Rainmeter/
├── DisplayServices/       Permanent shell assemblies
├── Modules/               Optional operational modules
├── Components/            Shared meter styles and includes
├── Layouts/               Rainmeter layout definitions
├── Installer/             Installation and recovery tooling
└── @Resources/
    ├── Data/
    ├── Images/
    ├── Lua/
    ├── Scripts/
    ├── Styles/
    └── Variables/
```

## 5. Safety requirements

- REOS shall not hide the Windows taskbar or desktop icons during installation.
- Full-shell presentation shall be explicitly enabled by the operator.
- A standalone recovery script shall restore Windows Explorer, desktop icons, and the taskbar.
- All display modules shall remain independently unloadable through Rainmeter.

## 6. Initial target

The first supported layout is 1920×1080 at 100 percent Windows scaling. Additional layouts shall be added after the baseline is stable.
