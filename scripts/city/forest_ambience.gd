extends Node
var world
var wind: AudioStreamPlayer
var water: AudioStreamPlayer
func _ready() -> void:
	if DisplayServer.get_name()=="headless": return
	wind = loop("res://assets/audio/navigation/wind.wav",-39)
	water = loop("res://assets/audio/chapter/foley/water.wav",-50)
func loop(path: String,volume: float) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	var stream := AudioStreamWAV.load_from_file(path)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD; stream.loop_end = stream.data.size()/(4 if stream.stereo else 2)
	voice.stream = stream; voice.bus = get_node("/root/GamePreferences").ambience_bus; voice.volume_db = volume; add_child(voice); voice.play()
	return voice
func _process(_delta: float) -> void:
	if not is_instance_valid(water): return
	water.volume_db = lerpf(-30,-58,clampf(absf(world.player.position.x-1460)/450,0,1))
