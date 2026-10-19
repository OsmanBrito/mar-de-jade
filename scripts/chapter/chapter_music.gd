extends Node
## Persistent chapter score; navigation keeps its own playlist and audio settings.
const ROOT := "res://assets/audio/chapter/music/"
const FADE_SECONDS := 1.4
var tracks: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var cache: Dictionary = {}
var positions: Dictionary = {}
var weights: Array[float] = [0.0,0.0]
var starts: Array[float] = [0.0,0.0]
var current_track := ""
var current_context := ""
var active_slot := -1
var fade := 1.0
var duck_db := 0.0
var target_duck_db := 0.0
var music_level := 0.6
var muted := false
var enabled := false
var allow_headless_audio := false
var auto_follow := true
var settings_path := "user://capitulo-audio.cfg"
var settings_dirty := false
var settings_clock := 0.0
var preferences:
	get: return get_node("/root/GamePreferences")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	tracks = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"playlist.json")).tracks
	load_settings()
	if settings_path=="user://capitulo-audio.cfg":
		_sync_preferences(); preferences.changed.connect(_sync_preferences)
	enabled = DisplayServer.get_name()!="headless" or allow_headless_audio
	for i in 2:
		var voice := AudioStreamPlayer.new(); voice.volume_db = -80; add_child(voice); voices.append(voice)

func context_for(scene: Node) -> String:
	if not is_instance_valid(scene) or scene.get_script()==null: return ""
	var script_path: String = scene.get_script().resource_path
	match script_path.get_file():
		"forest_hunt_director.gd": return "training" if scene.phase=="battle" else "forest"
		"name_entry.gd", "opening_director.gd", "adult_opening_director.gd": return "shelter"
		"plaza_director.gd": return "shelter" if is_instance_valid(scene.world) and scene.world.has_meta("order_convent") else "city"
		"promise_director.gd": return "promise"
		"training_director.gd":
			return "training" if scene.battle_container.visible else "city"
		"chapter_flow.gd":
			if scene.battle_container!=null and scene.battle_container.visible:
				return "duel" if scene.battle_host.combat.encounter=="portugal_duel" else "training"
			if scene.scene_index in [9,10,11,12]: return "recovery"
			if is_instance_valid(scene.world) and scene.world.has_meta("order_convent"): return "shelter"
			if scene.routes!=null and scene.routes.continuous():
				return "harbor" if scene.routes.area()=="cais" else "city"
			if scene.map_kind in ["cais","service","deck"]: return "harbor"
			return "shelter" if scene.map_kind in ["room","convent"] else "city"
		"combat_study.gd": return "duel" if scene.encounter=="duel" else "training"
	# In particular, voyage.gd owns its existing maritime music. Fade ours out.
	return ""

func follow_scene(scene: Node) -> void:
	set_context(context_for(scene))
	target_duck_db = 0
	if not is_instance_valid(scene): return
	var script_path: String = scene.get_script().resource_path if scene.get_script()!=null else ""
	if script_path.get_file() in ["opening_director.gd","plaza_director.gd","promise_director.gd","adult_opening_director.gd","training_director.gd","forest_hunt_director.gd","chapter_flow.gd"]:
		if scene.paused: target_duck_db = -10
		# Opening and promise have no phase property. The resolved music context
		# already tells us whether a real battle is currently on screen.
		elif current_context not in ["training","duel"]: target_duck_db = -4

func stream_for(id: String) -> AudioStream:
	if cache.has(id): return cache[id]
	if not tracks.has(id): return null
	if not tracks[id].get("enabled",true): return null
	var path: String = ROOT+tracks[id].file
	var stream: AudioStream
	if path.get_extension()=="mp3":
		var mp3 := AudioStreamMP3.new(); mp3.data = FileAccess.get_file_as_bytes(path); mp3.loop = true; stream = mp3
	else:
		var ogg := AudioStreamOggVorbis.load_from_file(path)
		if ogg!=null: ogg.loop = true
		stream = ogg
	if stream!=null: cache[id] = stream
	return stream

func set_context(id: String) -> void:
	if id==current_context: return
	if not id.is_empty() and not tracks.has(id):
		push_warning("Unknown chapter music context: "+id); return
	current_context = id
	if id==current_track: return
	if active_slot>=0 and voices[active_slot].playing:
		positions[current_track] = voices[active_slot].get_playback_position()
	current_track = id
	starts.assign(weights); fade = 0
	if id.is_empty(): active_slot = -1; return
	if not tracks[id].get("enabled",true): active_slot = -1; return
	if not enabled: active_slot = -1; return
	# Reversing a transition reuses the still-playing voice, without restarting it.
	for i in voices.size():
		if voices[i].playing and voices[i].get_meta("track","")==id:
			active_slot = i; return
	var stream := stream_for(id)
	if stream==null:
		active_slot = -1; push_error("Cannot load chapter music: "+id); return
	active_slot = 0 if weights[0]<=weights[1] else 1
	voices[active_slot].stop()
	voices[active_slot].stream = stream
	voices[active_slot].set_meta("track",id)
	voices[active_slot].play(fposmod(float(positions.get(id,0)),maxf(1,stream.get_length())))

func _process(delta: float) -> void:
	if auto_follow: follow_scene(get_tree().current_scene)
	update_mix(delta)
	if settings_dirty:
		settings_clock += delta
		if settings_clock>=0.4: save_settings()

func update_mix(delta: float) -> void:
	fade = minf(1,fade+maxf(0,delta)/FADE_SECONDS)
	duck_db = move_toward(duck_db,target_duck_db,maxf(0,delta)*14)
	for i in voices.size():
		weights[i] = lerpf(starts[i],1.0 if i==active_slot else 0.0,smoothstep(0,1,fade))
		var id: String = voices[i].get_meta("track","")
		var gain_db := float(tracks.get(id,{}).get("gain_db",-12))
		var gain := weights[i]*music_level*(0.0 if muted else 1.0)
		voices[i].volume_db = -80 if gain<=0.0001 else maxf(-80,gain_db+duck_db+linear_to_db(gain))
		if fade>=1 and i!=active_slot: voices[i].stop()

func set_level(value: float,persist: bool = true) -> void:
	if not is_finite(value): return
	music_level = clampf(value,0,1)
	if persist and settings_path=="user://capitulo-audio.cfg": preferences.set_level("music",music_level)
	if persist: settings_dirty = true; settings_clock = 0
	update_mix(0)
func set_muted(value: bool,persist: bool = true) -> void:
	muted = value
	if persist and settings_path=="user://capitulo-audio.cfg": preferences.set_music_muted(value)
	if persist: settings_dirty = true; settings_clock = 0
	update_mix(0)
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path)!=OK: return
	var value: Variant = config.get_value("music","level",0.6)
	if (value is int or value is float) and is_finite(float(value)): music_level = clampf(float(value),0,1)
	var mute_value: Variant = config.get_value("music","muted",false)
	if mute_value is bool: muted = mute_value
func save_settings() -> Error:
	var config := ConfigFile.new(); config.set_value("music","level",music_level); config.set_value("music","muted",muted)
	var result := config.save(settings_path)
	if result==OK: settings_dirty = false; settings_clock = 0
	return result
func _exit_tree() -> void:
	if settings_dirty: save_settings()
	for voice in voices: voice.stop()

func _sync_preferences() -> void:
	music_level = preferences.levels.music; muted = preferences.music_muted
	update_mix(0)
