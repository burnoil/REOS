; REOS v0.3 — Responsive console layout primitives
; Initial supported profiles: Wide16x9 and Compact3x2.
; Values are derived from the current Rainmeter work area.

[Variables]
ScreenW=#WORKAREAWIDTH#
ScreenH=#WORKAREAHEIGHT#

; Profile breakpoints
CompactAspectThreshold=1.60
IsCompact=(#ScreenW# / #ScreenH# < #CompactAspectThreshold# ? 1 : 0)

; Structural regions
OuterMargin=(#IsCompact# = 1 ? 8 : 10)
HeaderHeight=(#IsCompact# = 1 ? 94 : 112)
BottomRailHeight=(#IsCompact# = 1 ? 54 : 62)
NavigationWidth=(#IsCompact# = 1 ? 244 : 292)
SystemsRailWidth=(#IsCompact# = 1 ? 304 : 356)
RegionGap=(#IsCompact# = 1 ? 8 : 10)

HeaderX=#OuterMargin#
HeaderY=#OuterMargin#
HeaderW=(#ScreenW#-(#OuterMargin#*2))

ContentTop=(#HeaderY#+#HeaderHeight#+#RegionGap#)
ContentBottom=(#ScreenH#-#OuterMargin#-#BottomRailHeight#-#RegionGap#)
ContentHeight=(#ContentBottom#-#ContentTop#)

NavigationX=#OuterMargin#
NavigationY=#ContentTop#
NavigationH=#ContentHeight#

SystemsRailX=(#ScreenW#-#OuterMargin#-#SystemsRailWidth#)
SystemsRailY=#ContentTop#
SystemsRailH=#ContentHeight#

WorkspaceX=(#NavigationX#+#NavigationWidth#+#RegionGap#)
WorkspaceY=#ContentTop#
WorkspaceW=(#SystemsRailX#-#RegionGap#-#WorkspaceX#)
WorkspaceH=#ContentHeight#

BottomRailX=#OuterMargin#
BottomRailY=(#ScreenH#-#OuterMargin#-#BottomRailHeight#)
BottomRailW=(#ScreenW#-(#OuterMargin#*2))

; Workspace subdivisions
WorkspaceTopRowH=(#WorkspaceH#*0.27)
WorkspaceStowageH=(#IsCompact# = 1 ? 168 : 192)
WorkspaceProgramW=(#WorkspaceW#*0.34)
WorkspaceMainH=(#WorkspaceH#-#WorkspaceTopRowH#-#WorkspaceStowageH#-(#RegionGap#*2))

; Header subdivisions
BadgeW=(#IsCompact# = 1 ? 248 : 310)
SystemPlateW=(#IsCompact# = 1 ? 360 : 420)
HeaderIdentityX=(#HeaderX#+#BadgeW#+#RegionGap#)
HeaderIdentityW=(#HeaderW#-#BadgeW#-#RegionGap#)
