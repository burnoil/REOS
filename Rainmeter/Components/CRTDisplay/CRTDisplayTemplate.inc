; REOS v0.3 — CRT display construction template
; Include Colors.inc, Typography.inc, and Materials.inc before this file.
;
; Required variables supplied by the consuming skin:
; DisplayX, DisplayY, DisplayW, DisplayH, DisplayTitle

[MeterCRTOuterShadow]
Meter=Shape
X=(#DisplayX#+3)
Y=(#DisplayY#+4)
Shape=Rectangle 0,0,#DisplayW#,#DisplayH#,#DisplayRadius# | Fill Color #CRTShadow# | StrokeWidth 0
DynamicVariables=1

[MeterCRTBezel]
Meter=Shape
X=#DisplayX#
Y=#DisplayY#
Shape=Rectangle 0,0,#DisplayW#,#DisplayH#,#DisplayRadius# | Fill Color #DisplayBezelFill# | StrokeWidth 2 | Stroke Color #ModuleEdgeDark#
DynamicVariables=1

[MeterCRTGlass]
Meter=Shape
X=(#DisplayX#+9)
Y=(#DisplayY#+10)
Shape=Rectangle 0,0,(#DisplayW#-18),(#DisplayH#-20),(#DisplayRadius#-3) | Fill Color #DisplayGlassFill# | StrokeWidth 1 | Stroke Color #DisplayGlassStroke#
DynamicVariables=1

[MeterCRTGlassHighlight]
Meter=Shape
X=(#DisplayX#+13)
Y=(#DisplayY#+14)
Shape=Path GlassPath | StrokeWidth 1 | Stroke Color 255,255,255,#GlassHighlightAlpha# | Fill Color 0,0,0,0
GlassPath=0,16 | CurveTo 22,0,52,0,(#DisplayW#-46),0
DynamicVariables=1

[MeterCRTTitlePlate]
Meter=Shape
X=(#DisplayX#+12)
Y=(#DisplayY#-3)
Shape=Rectangle 0,0,(#DisplayW#*0.42),#PlateHeight#,3 | Fill Color #PlateFill# | StrokeWidth 1 | Stroke Color #PlateStroke#
DynamicVariables=1

[MeterCRTTitle]
Meter=String
X=(#DisplayX#+22)
Y=(#DisplayY#+3)
W=(#DisplayW#*0.40)
H=(#PlateHeight#-4)
Text=#DisplayTitle#
FontFace=#FontDisplay#
FontSize=#TypeModuleTitleSize#
FontWeight=#TypeWeightMedium#
FontColor=#PlateText#
StringCase=Upper
AntiAlias=1
ClipString=1
DynamicVariables=1

[MeterCRTFastenerTL]
Meter=Shape
X=(#DisplayX#+5)
Y=(#DisplayY#+5)
Shape=Ellipse 0,0,#FastenerSize#,#FastenerSize# | Fill Color #ConsoleSeam# | StrokeWidth 1 | Stroke Color #ConsoleHighlight#
DynamicVariables=1

[MeterCRTFastenerTR]
Meter=Shape
X=(#DisplayX#+#DisplayW#-8)
Y=(#DisplayY#+5)
Shape=Ellipse 0,0,#FastenerSize#,#FastenerSize# | Fill Color #ConsoleSeam# | StrokeWidth 1 | Stroke Color #ConsoleHighlight#
DynamicVariables=1

[MeterCRTFastenerBL]
Meter=Shape
X=(#DisplayX#+5)
Y=(#DisplayY#+#DisplayH#-8)
Shape=Ellipse 0,0,#FastenerSize#,#FastenerSize# | Fill Color #ConsoleSeam# | StrokeWidth 1 | Stroke Color #ConsoleHighlight#
DynamicVariables=1

[MeterCRTFastenerBR]
Meter=Shape
X=(#DisplayX#+#DisplayW#-8)
Y=(#DisplayY#+#DisplayH#-8)
Shape=Ellipse 0,0,#FastenerSize#,#FastenerSize# | Fill Color #ConsoleSeam# | StrokeWidth 1 | Stroke Color #ConsoleHighlight#
DynamicVariables=1
