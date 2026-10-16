extends Node
## Supplied MP3s, original ambience, and independent navigation-only buses.
const ROOT := "res://assets/audio/navigation/"
const PLAYLIST := ROOT+"music/playlist.json"
const LOOPS := ["sea","wind","bow_wash","rigging"]
const CUES := ["gull","creak","discovery","hull_wave_l","hull_wave_r","sail_flap"]
var sea: AudioStreamPlayer
var wind: AudioStreamPlayer
var wash: AudioStreamPlayer
var rigging: AudioStreamPlayer
var detail: AudioStreamPlayer
var fabric: AudioStreamPlayer
var hull_voices: Array[AudioStreamPlayer] = []
var music: Array[AudioStreamPlayer] = []
var effects: Dictionary = {}
var tracks: Array = []
var enabled := false
var allow_headless_audio := false
var settings_path := "user://navegacao-audio.cfg"
var levels := {"music":0.65,"ambience":0.85,"effects":0.85}
var bus_names: Array[String] = []
var buses: Dictionary = {}
var lowpass: AudioEffectLowPassFilter
var detail_clock := 0.0
var impact_clock := 0.0
var impact_serial := 0
var track_index := 0
var current_slot := 0
var outgoing_slot := -1
var fade_time := 0.0
var fade_duration := 3.0
var fading := true
var queued_next := false
var weights := [0.0,0.0]
var music_duck := -7.0
var settings_dirty := false
var settings_clock := 0.0

func _ready() -> void:
	load_settings()
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLAYLIST))
	if manifest is Dictionary: tracks = manifest.get("tracks",[])
	enabled = DisplayServer.get_name()!="headless" or allow_headless_audio
	if not enabled: return
	for key in ["music","ambience","effects"]: add_bus(key)
	for key in ["hull_l","hull_r"]:
		add_bus(key,"ambience")
		var panner := AudioEffectPanner.new(); panner.pan = -0.5 if key=="hull_l" else 0.5
		AudioServer.add_bus_effect(AudioServer.get_bus_index(buses[key]),panner)
	lowpass = AudioEffectLowPassFilter.new(); lowpass.cutoff_hz = 12000
	AudioServer.add_bus_effect(AudioServer.get_bus_index(buses.ambience),lowpass)
	for key in levels: apply_level(key)
	for id in LOOPS+CUES:
		var stream := AudioStreamWAV.load_from_file(ROOT+id+".wav")
		if stream==null: continue
		if id in LOOPS:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD; stream.loop_begin = 0; stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
		effects[id] = stream
	sea = loop_voice("sea"); wind = loop_voice("wind"); wash = loop_voice("bow_wash"); rigging = loop_voice("rigging")
	detail = voice("effects"); fabric = voice("ambience")
	hull_voices = [voice("hull_l"),voice("hull_r")]
	for i in 2:
		var player := voice("music"); player.finished.connect(func(): track_finished(i)); music.append(player)
	if not tracks.is_empty(): play_slot(0,0)
func add_bus(key: String,parent: String = "") -> void:
	var bus_name := "Voyage_"+str(get_instance_id())+"_"+key
	AudioServer.add_bus(); var index := AudioServer.bus_count-1
	AudioServer.set_bus_name(index,bus_name)
	AudioServer.set_bus_send(index,buses.get(parent,"Master"))
	buses[key] = bus_name; bus_names.append(bus_name)
func voice(bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new(); player.bus = buses[bus]; player.volume_db = -80
	add_child(player); return player
func loop_voice(id: String) -> AudioStreamPlayer:
	var player := voice("ambience"); player.stream = effects.get(id)
	if player.stream!=null: player.play()
	return player
func _process(delta: float) -> void:
	if settings_dirty:
		settings_clock += delta
		if settings_clock>=0.4: save_settings()
func update_mix(delta: float,phase: String,active: bool,speed: float,risk: float) -> void:
	if not enabled: return
	detail_clock = maxf(0,detail_clock-delta); impact_clock = maxf(0,impact_clock-delta)
	var at_sea := phase in ["sea","naval","naval_result"]
	var on_deck := phase=="deck"
	var travel := clampf(speed/100.0,0,1); var heavy := clampf(risk,0,1)
	var duck := 0.0 if active else -7.0
	sea.volume_db = move_toward(sea.volume_db,(-13.0 if at_sea else -24.0)+travel*3+heavy*3+duck,delta*12)
	wind.volume_db = move_toward(wind.volume_db,(-25.0 if at_sea else -38.0)+travel*4+heavy*5+duck,delta*12)
	wash.volume_db = move_toward(wash.volume_db,(-35.0+travel*20 if at_sea else -46.0)+duck,delta*14)
	rigging.volume_db = move_toward(rigging.volume_db,(-27.0 if at_sea or on_deck else -48.0)+travel*5+heavy*4+duck,delta*12)
	lowpass.cutoff_hz = move_toward(lowpass.cutoff_hz,3200.0 if on_deck else 12000.0,delta*11000)
	var music_target := -5.0 if phase in ["naval","boarding","game_over"] else 0.0
	if not active: music_target -= 7
	music_duck = move_toward(music_duck,music_target,delta*5)
	update_music(delta)
func update_music(delta: float) -> void:
	if tracks.is_empty() or music.is_empty(): return
	var player := music[current_slot]
	if not fading and player.playing and player.stream.get_length()-player.get_playback_position()<=5.0: next_track()
	if fading:
		fade_time = minf(fade_duration,fade_time+delta)
		var fraction := fade_time/fade_duration
		weights[current_slot] = sin(fraction*PI*0.5)
		if outgoing_slot>=0: weights[outgoing_slot] = cos(fraction*PI*0.5)
		if fraction>=1:
			fading = false
			if outgoing_slot>=0: music[outgoing_slot].stop(); weights[outgoing_slot] = 0
			outgoing_slot = -1
			if queued_next: queued_next = false; next_track()
	for i in 2:
		var trim := float(music[i].get_meta("gain_db",0))
		music[i].volume_db = -80 if weights[i]<=0.0001 else trim-6.0+music_duck+linear_to_db(weights[i])
func play_slot(slot: int,index: int) -> void:
	var path: String = ROOT+"music/"+str(tracks[index].file)
	var stream := AudioStreamMP3.new(); stream.data = FileAccess.get_file_as_bytes(path)
	stream.loop = false
	music[slot].stream = stream; music[slot].set_meta("gain_db",tracks[index].gain_db)
	music[slot].volume_db = -80; music[slot].play()
func next_track() -> void:
	if not enabled or tracks.is_empty(): return
	if fading: queued_next = true; return
	outgoing_slot = current_slot; current_slot = 1-current_slot
	track_index = (track_index+1)%tracks.size(); weights[current_slot] = 0
	play_slot(current_slot,track_index)
	fade_time = 0; fade_duration = 5; fading = true
func track_finished(slot: int) -> void:
	if slot==current_slot and not fading: next_track()
func track_title() -> String:
	return "Sem faixa disponível" if tracks.is_empty() else str(tracks[track_index].title)
func cue(id: String,pan_hint: float = 0.0) -> void:
	if not enabled or not effects.has(id) or (detail_clock>0 and id!="discovery"): return
	detail.stream = effects[id]; detail.pitch_scale = 1+clampf(pan_hint,-1,1)*0.06
	detail.volume_db = -16 if id=="discovery" else -23
	detail.play(); detail_clock = 12 if id=="gull" else 7
func sail_shift() -> void:
	if not enabled: return
	fabric.stream = effects.get("sail_flap"); fabric.volume_db = -13; fabric.play()
func wave_hit(strength: float,side: int) -> void:
	if not enabled or impact_clock>0: return
	var index := posmod(side,2); var player := hull_voices[index]
	player.stream = effects["hull_wave_l" if index==0 else "hull_wave_r"]
	player.volume_db = lerpf(-17,-6,clampf(strength,0,1))
	player.pitch_scale = lerpf(0.91,1.08,fmod(impact_serial*0.37,1))
	player.play(); impact_serial += 1; impact_clock = 1.25
func set_level(key: String,value: float) -> void:
	if not levels.has(key): return
	levels[key] = clampf(value,0,1); apply_level(key)
	settings_dirty = true; settings_clock = 0
func apply_level(key: String) -> void:
	if not buses.has(key): return
	var index := AudioServer.get_bus_index(buses[key]); var value: float = levels[key]
	AudioServer.set_bus_mute(index,value<=0)
	AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,0.001)))
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path)!=OK: return
	for key in levels:
		var value: Variant = config.get_value("audio",key,levels[key])
		if (value is int or value is float) and is_finite(float(value)): levels[key] = clampf(value,0,1)
func save_settings() -> Error:
	var config := ConfigFile.new()
	for key in levels: config.set_value("audio",key,levels[key])
	var error := config.save(settings_path)
	if error==OK: settings_dirty = false; settings_clock = 0
	return error
func _exit_tree() -> void:
	if settings_dirty: save_settings()
	for child in get_children():
		if child is AudioStreamPlayer: child.stop()
	for i in range(bus_names.size()-1,-1,-1):
		var index := AudioServer.get_bus_index(bus_names[i])
		if index>=0: AudioServer.remove_bus(index)
