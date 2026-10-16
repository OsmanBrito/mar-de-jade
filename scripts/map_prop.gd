@tool
extends Node2D
## Instance identity is separate from the reusable presentation scene.
@export var object_id: StringName
@export var sloped_depth: bool = false
var _last_polygon := PackedVector2Array()

func _ready() -> void:
	_refresh_depth()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and sloped_depth:
		_refresh_depth()

func _refresh_depth() -> void:
	if not sloped_depth:
		return
	var collision = get_node("Body/Footprint") as CollisionPolygon2D
	if collision.polygon == _last_polygon:
		return
	_last_polygon = collision.polygon.duplicate()
	for child in get_children():
		if not child is Sprite2D:
			continue
		var strip := child as Sprite2D
		var sample_x = strip.position.x + strip.texture.get_width()*strip.scale.x*0.5
		var ground_y = -INF
		for edge in _last_polygon.size():
			var a = _last_polygon[edge]
			var b = _last_polygon[(edge+1)%_last_polygon.size()]
			if absf(b.x-a.x) < 0.001:
				continue
			var weight = (sample_x-a.x)/(b.x-a.x)
			if weight >= 0.0 and weight <= 1.0:
				ground_y = maxf(ground_y,lerpf(a.y,b.y,weight))
		if ground_y == -INF:
			continue
		# Preserve the artwork's top while moving the strip's sorting origin.
		var top = strip.position.y+strip.offset.y*strip.scale.y
		strip.position.y = ground_y
		strip.offset.y = (top-ground_y)/strip.scale.y
