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
	var previous_frame:=frame_time
	# Consume close grid points before the base controller chooses a direction.
	while enabled and not destination_path.is_empty() and position.distance_to(destination_path[0])<8:
		destination_path.remove_at(0)
	super._physics_process(delta)
	if presentation.identity=="hero_child":
		frame_time=fposmod(previous_frame+position.distance_to(before)/21.0,3.0) if walking else 0.0
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
