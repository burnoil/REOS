# REOS Native Windows Interaction Specification

Status: Approved design baseline  
Scope: REOS 0.2 application lifecycle and Windows interoperability

## Purpose

REOS is a workstation layer over Windows, not a replacement shell. It must make common work calmer and more coherent without trapping the operator or weakening mature Windows behavior.

## Governing rule

REOS provides the normal path. Native Windows remains the immediate escape path.

## Native behaviors REOS must preserve

REOS must not intercept or disable:

- Alt+Tab and Ctrl+Alt+Tab
- Win+Tab and virtual desktops
- Win+Z and Windows Snap Layouts
- Win+Arrow window movement and snapping
- Win+Shift+Arrow monitor movement
- Alt+F4 and Alt+Space
- native title bars, system menus, file dialogs, context menus, UAC, accessibility shortcuts, or notification-area behavior

Windows applications must remain free to maximize, resize, snap, move between monitors, cover REOS, and restore to their Windows-managed positions.

## Taskbar relationship

Application Stowage is not a taskbar replacement. The taskbar remains authoritative for:

- notification-area applications
- pinned applications and jump lists
- progress and attention states
- unfamiliar or newly installed applications
- recovery if Rainmeter or REOS.Core fails

Console Mode may conceal or auto-hide the taskbar, but the operator must be able to reveal or restore it immediately.

## Functional ownership

- Alt+Tab: rapid switching among open windows
- Win+Tab: desktops and broad workspace organization
- Windows taskbar: complete native application and system access
- REOS Application Directory: launch and explicitly configured application actions
- REOS Application Stowage: retrieve intentionally minimized top-level windows with task context

## Stowage state model

REOS.Core owns grouping, ordering, classification, and individual window records. Rainmeter only renders the state and issues explicit commands.

A stowage group is keyed by application process family, not only by REOS label. Edge and Chrome may both be classified as RESEARCH TERMINAL, but remain separate groups.

Each group must include:

- GroupKey
- Process
- ApplicationName
- ReosLabel
- Count
- MostRecentTitle
- MostRecentHandle
- Windows[]

Each window record must include:

- Handle
- Process
- Title
- ReosLabel
- IsMinimized
- IsActive

## Group interaction

### Single minimized window

Primary click restores it immediately.

### Multiple minimized windows

Primary click opens an in-place instance selector. Selecting an item restores that exact window and returns to group view.

### Future explicit actions

- restore most recent
- restore all in group
- new window or new session
- close window using a normal close request
- reveal native Task View
- move to REOS monitor only when explicitly requested

No process termination command is part of the normal UI.

## Scope boundaries

REOS manages top-level Windows windows. It does not claim knowledge of internal tabs or documents unless an application-specific integration exists.

Examples:

- Edge and Chrome tabs are not separate REOS windows.
- Windows Terminal tabs are not separately visible to REOS.
- Notepad++ documents in one main window are not separate stowage items.
- Word document windows may be separate items when Windows exposes them as top-level windows.

## Multi-monitor behavior

- REOS remains on its assigned console monitor.
- Stowage tracks minimized windows across monitors.
- Restore uses the last Windows-managed position by default.
- Moving a window to the REOS display must be an explicit action.

## Virtual desktops

Initial implementation must not silently move windows between virtual desktops. Windows Task View remains authoritative. Cross-desktop awareness may be added only when it can be represented reliably and clearly.

## Failure behavior

If REOS.Core is unavailable or state is stale, Stowage must say so and direct the operator to native Windows controls. Rainmeter or REOS.Core failure must never prevent normal Windows use.

## Accessibility and discoverability

- Important state cannot rely on color alone.
- Click targets must be large and textual.
- Tooltips or visible legends must disclose secondary actions.
- Global shortcuts must be configurable and must not override Windows accessibility shortcuts.

## Implementation order

1. REOS.Core grouped state contract
2. Group overview cards
3. In-place instance selector
4. Explicit context actions
5. Native convenience bridge and recovery controls

No later phase should be implemented before the preceding state model is verified on a real workstation.
