extends Node
## Quiet shore ambience follows the actual chapter; voyage owns its own mix.
var sea: AudioStreamPlayer
var gull: AudioStreamPlayer
var clock := 19.0
var weight := 0.0
func _ready() -> void:
	sea = AudioStreamPlayer.new(); gull = AudioStreamPlayer.new()
	for voice in [sea,gull]: voice.bus = GamePreferences.ambience_bus; add_child(voice)
	var stream := AudioStreamWAV.load_from_file("res://assets/audio/navigation/sea.wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD; stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
	sea.stream = stream; sea.volume_db = -80
	gull.stream = AudioStreamWAV.load_from_file("res://assets/audio/navigation/gull.wav"); gull.volume_db = -33
func _process(delta: float) -> void:
	if DisplayServer.get_name()=="headless": return
	var context: String = get_node("/root/ChapterMusic").context_for(get_tree().current_scene)
	var target := 1.0 if context=="harbor" else 0.0
	weight = move_toward(weight,target,delta*0.5)
	sea.volume_db = -80 if weight<=0 else -30+linear_to_db(weight)
	if weight>0 and not sea.playing: sea.play()
	elif weight<=0 and sea.playing: sea.stop()
	clock -= delta
	if context=="harbor" and clock<=0:
		gull.play(); clock = 37.0
