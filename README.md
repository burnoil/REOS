# REOS

**Rockwell Engineering Operations System**

REOS is a Rainmeter-based engineering workstation environment for Windows. It is designed to make a modern Windows system feel like an internal Rockwell engineering platform that evolved continuously from the Shuttle era into the present day.

## Architecture

```text
Windows
  ↓
Rainmeter
  ↓
REOS Display Services
  ↓
Engineering Applications
```

Windows remains the operating system. Rainmeter provides the rendering and telemetry foundation. REOS supplies the Rockwell visual language, workstation framing, terminology, and display modules.

## Design intent

REOS is not a toy, novelty desktop, or science-fiction HUD. It is intended to feel ordinary, expected, functional, and ever-present: the workstation environment an engineer would use every day without thinking about it until it stopped working.

Primary references include Rockwell corporate and aerospace design, Shuttle-era Mission Control, Honeywell and Hughes human-factors practice, and the transitional industrial futurism of the late 1970s through early 1980s. Rockwell remains the identity.

Explicitly excluded:

- Cyberpunk and synthwave
- Dirty *Alien/Aliens*-style technology
- Fake CRT scanlines and terminal theatrics
- Floating holograms
- Decorative animation
- Generic retro-computing clichés

## Program status

**Phase:** Foundation  
**Current program build:** Milestone 0  
**Initial implementation target:** 1920×1080 Windows workstation using Rainmeter

## Planned structure

```text
REOS/
├── Documentation/
│   ├── Standards/
│   └── WorkOrders/
├── Rainmeter/
│   ├── DisplayServices/
│   ├── Modules/
│   ├── Components/
│   ├── Layouts/
│   ├── Installer/
│   └── @Resources/
├── Assets/
├── Mockups/
├── CHANGELOG.md
└── README.md
```

## Governing principle

> Engineering software succeeds when it becomes part of the engineer's thought process rather than part of the engineer's attention.

## Licensing and trademarks

This is an independent historical-design and desktop-customization project. Rockwell and related names and marks belong to their respective rights holders. No affiliation or endorsement is implied.
