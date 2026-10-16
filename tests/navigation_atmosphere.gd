extends SceneTree
const Sea = preload("res://scripts/navigation/voyage_sea.gd")
const Audio = preload("res://scripts/navigation/voyage_audio.gd")
var checks := 0
var failures: Array[String] = []
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	game._process(0); game.view.queue_redraw(); await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/navigation-"+id+".png")
func run() -> void:
	var start_buses := AudioServer.bus_count
	var sound = Audio.new(); sound.allow_headless_audio = true
	sound.settings_path = "res://tests/navigation-audio-fixture.cfg"; root.add_child(sound)
	sound.set_process(false)
	var supplied_tracks: int = sound.tracks.size()
	check(sound.tracks.size()==6 and sound.tracks[-1].title=="O vento no peito","All six supplied tracks, including O vento no peito, are in the playlist")
	check(sound.effects.size()==10 and sound.sea.playing and sound.wind.playing,"All ten original ambience and interaction layers load")
	for track in sound.tracks:
		var stream := AudioStreamMP3.new(); stream.data = FileAccess.get_file_as_bytes(Audio.ROOT+"music/"+track.file)
		check(stream.get_length()>170 and stream.get_length()<195 and track.gain_db< -7,"MP3 decodes at expected full length with loudness trim: "+track.title)
	check(AudioServer.bus_count==start_buses+5,"Navigation has independent music, ambience, effects and two panned hull buses")
	sound.update_mix(3,"sea",true,100,0)
	check(sound.weights[sound.current_slot]>0.99 and sound.music[sound.current_slot].playing,"Initial music fades in rather than starting at full level")
	var active_music_db: float = sound.music[sound.current_slot].volume_db
	sound.update_mix(2,"sea",false,100,0)
	check(sound.music[sound.current_slot].volume_db<active_music_db-6,"Opening a menu or dialogue lowers music smoothly")
	sound.update_mix(2,"sea",true,100,0)
	sound.next_track(); sound.update_music(2.5)
	check(sound.track_index==1 and sound.music[0].playing and sound.music[1].playing,"Track transition overlaps two playing streams")
	check(absf(float(sound.weights[0])*sound.weights[0]+float(sound.weights[1])*sound.weights[1]-1)<0.001,"Crossfade maintains constant power")
	sound.update_music(2.5)
	check(not sound.fading and not sound.music[0].playing and sound.music[1].playing,"Crossfade stops the outgoing track at completion")
	for i in sound.tracks.size()-1: sound.next_track(); sound.update_music(5)
	check(sound.track_index==0,"Playlist wraps after all supplied tracks")
	sound.music[sound.current_slot].seek(sound.music[sound.current_slot].stream.get_length()-3)
	await frames(4); sound.update_music(0.1)
	check(sound.fading and sound.track_index==1,"Playback position automatically starts the next track before the end")
	sound.update_music(5)
	sound.wave_hit(0.9,0); sound.wave_hit(0.9,1)
	check(sound.impact_serial==1 and sound.hull_voices[0].playing,"Wave impact has stereo placement and rejects duplicate hits in the same swell")
	sound.update_mix(2,"sea",true,100,0.8); sound.wave_hit(0.9,1)
	check(sound.impact_serial==2 and sound.hull_voices[1].playing,"The next wave can hit the opposite side")
	sound.sail_shift(); check(sound.fabric.playing,"Changing sail plays the cloth and rigging cue")
	sound.update_mix(3,"deck",true,0,0)
	check(sound.lowpass.cutoff_hz==3200,"Deck ambience is sheltered and filtered")
	sound.update_mix(3,"sea",true,0,0); var idle_wash: float = sound.wash.volume_db
	sound.update_mix(3,"sea",true,100,1)
	check(sound.wash.volume_db>idle_wash+15,"Bow water grows with speed rather than playing loudly at anchor")
	sound.set_level("music",0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(sound.buses.music)) and not AudioServer.is_bus_mute(AudioServer.get_bus_index(sound.buses.ambience)),"Muting music preserves the sea")
	sound.set_level("ambience",0.55); sound.set_level("effects",0.7)
	check(sound.save_settings()==OK,"Volume settings can be saved separately from campaign checkpoints")
	var saved = Audio.new(); saved.settings_path = sound.settings_path; saved.load_settings()
	check(saved.levels.music==0 and is_equal_approx(saved.levels.ambience,0.55) and is_equal_approx(saved.levels.effects,0.7),"Independent volume settings restore correctly")
	saved.free(); sound.queue_free(); await frames()
	check(AudioServer.bus_count==start_buses,"Leaving navigation removes its audio players and buses")
	game = load("res://scripts/navigation/voyage.gd").new(); game.auto_save = false
	game.audio_settings_path = "res://tests/navigation-atmosphere-defaults.cfg"
	root.add_child(game); await frames(); game.clear_overlay(); game.set_process(false)
	game.model.position = Vector2(11600,18800); game.model.heading = 2.52; game.sail_level = 3
	game.model.elapsed = 20; game.perspective.update_view(0,true)
	check(game.perspective.near_material.get_shader_parameter("detailed_mesh")==true,"Nearby sea uses the subdivided wave mesh")
	check(game.perspective.near_water.mesh.subdivide_width==160,"Wave geometry is dense nearby instead of subdividing the whole Atlantic")
	var camera_y: float = game.perspective.camera.position.y
	var saw_spray := false
	for i in 900:
		game._process(1.0/60)
		for particle in game.perspective.spray:
			if particle.node.visible: saw_spray = true
	check(game.perspective.splash_serial>0 and saw_spray,"Crossing a wave at full sail produces bow spray")
	check(is_equal_approx(game.perspective.player.position.y,Sea.height(game.model.position,game.model.elapsed)*0.8),"Ship flotation samples the same wave field as the water shader")
	check(game.perspective.camera.position.y==camera_y,"Waves move the ship while keeping the horizon stable")
	check(game.perspective.trail.size()<=240 and game.perspective.wake.any(func(node): return node.visible),"Wake follows recent positions with a bounded trail history")
	game.sail_level = 0; game.model.velocity = Vector2.ZERO
	var anchored_impacts: int = game.perspective.splash_serial
	for i in 540: game._process(1.0/60)
	check(game.perspective.splash_serial>anchored_impacts,"Waves also reach the stationary hull, with softer impacts at anchor")
	game.model.elapsed = 2; game.perspective.update_view(0)
	check(game.perspective.last_impact_time<game.model.elapsed and game.perspective.trail.is_empty(),"Loading an earlier voyage time resets wave cooldown and wake history")
	var frozen: Transform3D = game.perspective.player.transform
	game.open_pause(); game._process(4)
	check(game.perspective.player.transform==frozen,"Pause freezes water and ship motion")
	game.open_audio()
	var sliders: Array[Node] = game.modal_root.find_children("*","HSlider",true,false)
	check(sliders.size()==3 and game.overlay=="audio","Sound panel exposes three independent volume sliders")
	game.ambience.settings_path = "res://tests/navigation-audio-ui-fixture.cfg"
	for slider in sliders:
		if slider.name=="music": slider.value = 40
	check(is_equal_approx(game.ambience.levels.music,0.4) and is_equal_approx(game.ambience.levels.ambience,0.85),"Music slider changes only music, preserving ambience")
	await capture("sound-menu")
	game.close_audio(); game.clear_overlay(); game.model.phase = "sea"
	game.model.position = Vector2(11600,18800); game.model.elapsed = 30; game.sail_level = 3
	game.model.velocity = Vector2.from_angle(game.model.heading)*95
	game.notice("Vela plena · ondas, espuma e o som da água na proa.")
	game._process(0.05); game.perspective.bow_impact(0.9); game._process(0.08)
	await capture("waves")
	var splash_events: int = game.perspective.splash_serial
	game.queue_free(); await frames()
	check(AudioServer.bus_count==start_buses,"Gameplay scene cleanup restores the original audio bus layout")
	var result := {"checks":checks,"failures":failures,"rendered":DisplayServer.get_name()!="headless","supplied_tracks":supplied_tracks,"splash_events":splash_events}
	var report := FileAccess.open("res://tests/navigation-atmosphere-report.json",FileAccess.WRITE); report.store_string(JSON.stringify(result,"\t")); report.close()
	print("ATMOSPHERE_RESULT ",JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
