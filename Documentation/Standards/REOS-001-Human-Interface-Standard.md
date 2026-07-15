# REOS-001

## Rockwell Engineering Operations System Human Interface Standard

**Revision:** A  
**Status:** Released for internal development  
**Owning organization:** Engineering Information Systems  
**Applies to:** All REOS Display Services and modules

## 1. Purpose

This standard establishes the visual, operational, and human-factors rules governing REOS.

REOS shall support engineering work while minimizing operator distraction. The environment shall feel permanent, familiar, functional, and expected.

## 2. Operating principle

REOS exists to support engineering. It is never the center of attention.

The operator shall spend the majority of attention on engineering tasks rather than on the operating environment.

## 3. Platform architecture

```text
Windows
  ↓
Rainmeter
  ↓
REOS Display Services
  ↓
Engineering Applications
```

Rainmeter is the rendering and telemetry engine. REOS is the workstation environment presented to the operator.

## 4. Identity

Rockwell shall be presented directly. REOS shall not use a substitute company, parody identity, or alternate corporate mark.

Supporting design references may include Shuttle-era NASA, Honeywell, Hughes, IBM, HP, and other period engineering systems, but the resulting environment shall remain unmistakably Rockwell.

## 5. Visual character

REOS shall evoke a continuously maintained aerospace engineering environment whose design lineage began in the late 1970s and early 1980s.

The environment shall be:

- Functional
- Calm
- Lived-in but maintained
- Civilian and professional
- Dense where engineering work requires density
- Visually quiet where no action is required
- Familiar enough to become forgettable through routine use

REOS shall not use:

- Cyberpunk, synthwave, or neon effects
- Dirty or distressed *Alien/Aliens*-style technology
- Fake CRT scanlines or phosphor theatrics
- Holographic or floating interface conventions
- Decorative animation
- Excessive glow, transparency, or glass effects

## 6. Materials and color

The interface shall suggest practical workstation materials rather than decorative textures:

- Warm equipment white and eggshell
- Molded blue-gray engineering plastic
- Mission/Shuttle blue and canary blue
- Matte anti-glare display surfaces
- Restrained metal identification plates
- Small green, amber, and red indicators

Status colors are reserved:

- Green: nominal or available
- Amber: advisory or operator attention
- Red: fault or immediate action

Red shall never be decorative.

## 7. Layout

The central operator workspace is the primary region. Display Services shall frame engineering applications and shall not unnecessarily overlap the work area.

Persistent assemblies may include:

- Header Assembly
- Operations Directory
- Operator Workspace Frame
- System Instrumentation
- System Status Bus

All assemblies shall align to a shared grid and use consistent margins, gaps, typography, and identification conventions.

## 8. Terminology

Preferred REOS terms:

| Consumer term | REOS term |
|---|---|
| Desktop | Operator Workspace |
| App | Engineering Application |
| Widget | Display Module |
| Settings | Configuration Control |
| File Explorer | Engineering Document Control |
| Downloads | Incoming Technical Data |
| Task Manager | System Resource Analysis |
| Event Viewer | Operations Event Record |
| Notification | Message Traffic |
| Error | Condition or Status Notice |

Terminology shall be precise without becoming theatrical.

## 9. Status and faults

REOS shall present faults calmly and directly.

A status notice should identify:

1. Subsystem
2. Condition
3. Operator action
4. Reference number

Avoid emotional wording such as “fatal,” “oops,” or “something went wrong” unless technically required.

## 10. Motion and sound

Motion shall communicate progress, transition, or state only. Blinking is reserved for conditions requiring operator attention.

Sound shall be rare, restrained, and functional. Silence is the normal state.

## 11. Institutional continuity

REOS shall appear to have evolved rather than been reinvented. Legacy names, conventions, and layouts may remain when they continue to support operator familiarity and documented procedures.

## 12. Design review test

Every component shall answer the following questions:

- Does this help the operator perform engineering work?
- Would Rockwell Engineering approve it for routine use?
- Will the operator stop noticing it after becoming familiar with it?
- Does it look and behave as though it belongs to the same institution as every other REOS component?

A component that exists only because it looks interesting shall not be approved.
