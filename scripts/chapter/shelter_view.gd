@tool
extends Node2D
@export var room_size := Vector2i(8,7)

func _ready() -> void:
	preload("res://scripts/chapter/shelter_details.gd").install(self)

func _draw() -> void:
	var ground = get_node_or_null("Ground") as TileMapLayer
	if ground == null or ground.tile_set == null:
		return
	preload("res://scripts/chapter/shelter_details.gd").draw_walls(self,ground,room_size)
