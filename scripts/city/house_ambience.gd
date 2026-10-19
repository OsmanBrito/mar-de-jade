extends Node
## Quiet local foley uses the player's existing ambience bus and stops with the map.
var world
var water: AudioStreamPlayer
var wind: AudioStreamPlayer
var bell: AudioStreamPlayer
var work: AudioStreamPlayer
var interaction: AudioStreamPlayer
static var bell_stream: AudioStreamWAV
var clock := 0.0
var bell_clock := 0.0
var preferences:
	get: return get_node("/root/GamePreferences")
func _enter_tree() -> void:
	if is_instance_valid(wind): wind.call_deferred("play")
static func install(map: Node2D) -> void:
	if map.has_node("HouseAmbience"): return
	var sound := Node.new(); sound.name = "HouseAmbience"; sound.set_script(load("res://scripts/city/house_ambience.gd")); sound.world = map; map.add_child(sound)
func _ready() -> void:
	if DisplayServer.get_name()=="headless": return
	water = AudioStreamPlayer.new(); water.stream = preload("res://assets/audio/chapter/foley/water.wav"); water.bus = preferences.ambience_bus; water.volume_db = -34; add_child(water)
	wind = AudioStreamPlayer.new(); var air := AudioStreamWAV.load_from_file("res://assets/audio/navigation/wind.wav")
	air.loop_mode = AudioStreamWAV.LOOP_FORWARD; air.loop_end = air.data.size()/(4 if air.stereo else 2)
	wind.stream = air; wind.bus = preferences.ambience_bus; wind.volume_db = -40; add_child(wind); wind.play()
	bell = AudioStreamPlayer.new(); bell.stream = make_bell(); bell.bus = preferences.ambience_bus; bell.volume_db = -35; add_child(bell)
	work = AudioStreamPlayer.new(); work.bus = preferences.ambience_bus; work.volume_db = -36; add_child(work)
	interaction = AudioStreamPlayer.new(); interaction.bus = preferences.effects_bus; interaction.volume_db = -28; add_child(interaction)
func service(id: String) -> void:
	if not is_instance_valid(interaction): return
	interaction.stream = preload("res://assets/audio/chapter/foley/water.wav") if id=="water" else preload("res://assets/audio/chapter/foley/cup.wav")
	interaction.play()
static func make_bell() -> AudioStreamWAV:
	if bell_stream!=null: return bell_stream
	var samples := PackedByteArray(); samples.resize(22050*4*2)
	for i in 22050*4:
		var t := float(i)/22050; var value := 0.0
		for mode in [Vector3(220,1,1.7),Vector3(440,.45,1.2),Vector3(594,.3,.9),Vector3(902,.18,.55),Vector3(1188,.1,.35)]:
			value += sin(TAU*mode.x*t)*mode.y*exp(-t/mode.z)
		value *= minf(t/.004,1)*.36*clampf((4-t)*2,0,1)
		samples.encode_s16(i*2,int(clampf(value,-1,1)*32767))
	bell_stream = AudioStreamWAV.new(); bell_stream.format = AudioStreamWAV.FORMAT_16_BITS; bell_stream.mix_rate = 22050; bell_stream.data = samples
	return bell_stream
func _process(delta: float) -> void:
	if not is_instance_valid(water) or not is_instance_valid(world.player): return
	var inside: bool = world.has_meta("order_convent")
	var chapel: bool = inside and world.player.position.y<180 and world.player.position.x<400
	wind.volume_db = -54 if chapel else -48 if inside else -40
	clock += delta
	bell_clock += delta
	if bell_clock>75 and world.player.enabled:
		bell_clock = 0; bell.volume_db = -40 if inside else -35; bell.play()
	var source := Vector2(-5,580) if inside else Vector2(-935,245)
	if clock>17 and world.player.enabled:
		clock = 0
		if not chapel and world.player.position.distance_to(source)<350:
			water.volume_db = -32-world.player.position.distance_to(source)*.03; water.play()
		elif inside and world.player.position.y<230 and world.player.position.x>400:
			work.stream = preload("res://assets/audio/chapter/foley/cup.wav"); work.play()
		elif inside and world.player.position.x< -400:
			work.stream = preload("res://assets/audio/chapter/foley/cloth.wav"); work.play()
