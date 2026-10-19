extends "res://scripts/player.gd"
## Shared controller with the same illustrated protagonist identity used by the adult chapter.
var presentation: Node2D
var step_voice: AudioStreamPlayer
var step_distance := 0.0

func _ready() -> void:
	super._ready()
	sprite.hide()
	presentation = get_node("Presentation")
	step_voice = AudioStreamPlayer.new(); step_voice.volume_db = -30; step_voice.bus = GamePreferences.effects_bus; add_child(step_voice)
	var map: Node = get_parent()
	if map.name=="ActorsAndProps": map = map.get_parent()
	var wood: bool = map.get("map_id") in ["abrigo_infancia","abrigo_adulto","botafogo_departure","forest_hunt_map"]
	step_voice.stream = AudioStreamWAV.load_from_file("res://assets/audio/combat/footstep_wood.wav" if wood else "res://assets/audio/chapter/foley/stone_step.wav")

func _physics_process(delta: float) -> void:
	var before := position
	super._physics_process(delta)
	step_distance += position.distance_to(before)
	if step_distance>=26:
		step_distance = fmod(step_distance,26)
		if DisplayServer.get_name()!="headless": step_voice.play()
	presentation.walking = walking
	presentation.frame_time = frame_time
	presentation.facing = facing
	presentation.queue_redraw()

func _draw() -> void:
	pass # The illustrated presentation owns its ground contact shadow.
