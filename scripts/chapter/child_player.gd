extends "res://scripts/player.gd"
## Use the approved controller with provisional childhood presentation.
var presentation: Node2D

func _ready() -> void:
	super._ready()
	sprite.hide()
	presentation = get_node("Presentation")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	presentation.walking = walking
	presentation.frame_time = frame_time
	presentation.facing = facing
	presentation.queue_redraw()

func _draw() -> void:
	pass # Presentation draws its own provisional shadow.
