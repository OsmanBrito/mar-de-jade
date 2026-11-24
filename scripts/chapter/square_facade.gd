@tool
extends Node2D
## One painted building of the Lisbon square, editable in the 2D view.
## The node position is the building's front ground corner (where its two
## façades meet the pavement): drag the node to move the whole building.
## The child "Pintura" sprite holds the art; its offset keeps that corner here.

## Which back side of the square the building lines: "nw" shows its right
## façade along the square, "ne" its left façade.
@export_enum("nw","ne") var edge: String = "nw":
	set(value): edge = value; queue_redraw()
## Length (world units in x) of the façade facing the square.
@export var along: float = 140.0:
	set(value): along = value; queue_redraw()
## Length (world units in x) of the side going back into the block.
@export var depth: float = 140.0:
	set(value): depth = value; queue_redraw()

func _draw() -> void:
	# Soft contact shadow under the façade and into the block; no shadow is baked in the art.
	var front := Vector2(1,-0.5) if edge=="nw" else Vector2(-1,-0.5)
	var back := Vector2(-1,-0.5) if edge=="nw" else Vector2(1,-0.5)
	for ring in 4:
		var grow := 6.0+ring*7.0
		var a := Vector2(0,grow*0.5)-front*grow*0.3
		var b := a+front*(along+grow*0.6)
		draw_colored_polygon(PackedVector2Array([a,b,b+back*depth,a+back*depth]),Color(0.07,0.055,0.035,0.07))
