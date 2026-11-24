extends SceneTree
const Score = preload("res://scripts/chapter/chapter_music.gd")
var checks := 0
var failures: Array[String] = []
var scene
var score
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 4) -> void:
	for i in n: await process_frame
func mount(path: String) -> void:
	if is_instance_valid(scene): scene.free(); await frames(2)
	scene = load(path).instantiate(); root.add_child(scene); await frames()
func narrative_mix(expected: String) -> void:
	# Exercise _process against the real active scene, not just context_for().
	var singleton = root.get_node("ChapterMusic")
	current_scene = scene; await frames()
	check(singleton.current_track==expected,"Automatic narrative soundtrack: "+scene.name)
	check(singleton.target_duck_db==-4,"Narrative gain works with the scene's actual properties: "+scene.name)
	scene.paused = true; await frames()
	check(singleton.target_duck_db==-10,"Pause gain works on narrative scene: "+scene.name)
	scene.paused = false; await frames()
	check(singleton.target_duck_db==-4,"Unpause restores narrative gain: "+scene.name)
	current_scene = null; await frames()
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	score = Score.new(); score.auto_follow = false; score.allow_headless_audio = true; score.settings_path = "res://.godot/chapter-music-test.cfg"
	root.add_child(score); score.set_process(false); score.set_level(0.6,false); score.set_muted(false,false)
	check(score.tracks.size()==8,"Eight narrative contexts remain registered")
	for id in score.tracks:
		var stream: AudioStream = score.stream_for(id)
		check(score.tracks[id].get("enabled",true),"Every narrative context has a Mar de Ferro replacement: "+id)
		check(stream!=null and stream.get_length()>30,"Complete playable music: "+id)
		check(stream.loop,"Music loops: "+id)
		check(score.stream_for(id)==stream,"Music resource is cached: "+id)
	score.set_context("city"); score.update_mix(2)
	var city_slot: int = score.active_slot
	check(score.voices[city_slot].playing and score.weights[city_slot]==1,"Exploration music plays at its settled gain")
	score.set_context("city"); check(score.fade==1 and score.active_slot==city_slot,"Repeated dialogue updates do not restart the music")
	score.set_context("training"); score.update_mix(0.6)
	check(score.weights[0]>0 and score.weights[1]>0,"Combat entry crossfades both voices")
	score.set_context("city"); check(score.active_slot==city_slot,"Interrupted transition reuses the still-playing exploration voice")
	score.update_mix(2); check(score.voices.filter(func(voice): return voice.playing).size()==1,"Outgoing music stops after the fade")
	score.set_level(0,false); check(score.voices[city_slot].volume_db<=-80,"Zero music volume is silent")
	score.set_level(0.65,false); score.set_muted(true,false); check(score.voices[city_slot].volume_db<=-80,"Mute does not stop transport")
	score.set_muted(false,false); check(score.voices[city_slot].volume_db>-80,"Unmute restores the selected volume")
	score.set_context(""); score.update_mix(2); check(score.voices.all(func(voice): return not voice.playing),"Navigation handoff stops all chapter music")
	await mount("res://scenes/chapter_01/name_entry.tscn"); check(score.context_for(scene)=="shelter","Name entry has a peaceful theme")
	await mount("res://scenes/chapter_01/opening.tscn"); check(score.context_for(scene)=="shelter","Childhood shelter has music")
	await narrative_mix("shelter")
	await mount("res://scenes/chapter_01/plaza.tscn"); check(score.context_for(scene)=="city","Childhood plaza has city music")
	await narrative_mix("city")
	await mount("res://scenes/chapter_01/promise.tscn"); check(score.context_for(scene)=="promise","Promise uses its emotional theme")
	await narrative_mix("promise")
	var forest_context = Node2D.new(); forest_context.set_script(load("res://scripts/chapter/forest_hunt_director.gd"))
	check(score.context_for(forest_context)=="forest","Forest exploration selects the canopy theme")
	forest_context.set("phase","battle"); check(score.context_for(forest_context)=="training","Forest battle switches to the combat theme")
	forest_context.free()
	await mount("res://scenes/chapter_01/adult_opening.tscn"); check(score.context_for(scene)=="shelter","Adult opening has music")
	await narrative_mix("shelter")
	await mount("res://scenes/chapter_01/training.tscn")
	scene.battle_container.hide(); check(score.context_for(scene)=="city","Training dialogue stays on the exploration theme")
	await narrative_mix("city")
	scene.battle_container.show(); check(score.context_for(scene)=="training","Childhood combat selects training music")
	await mount("res://scenes/chapter_01/chapter_flow.tscn")
	scene._begin_battle("school"); score.follow_scene(scene); check(score.current_track=="training","Actual chapter combat selects training music")
	scene._begin_battle("duel"); score.follow_scene(scene); check(score.current_track=="duel","Leonor duel selects its combat theme")
	scene.battle_container.hide(); scene.phase = "dialogue"; score.follow_scene(scene)
	check(score.current_track=="city" and score.target_duck_db<0,"Leaving battle returns to quieter narrative music")
	scene.paused = true; score.follow_scene(scene); check(score.target_duck_db==-10,"Pause lowers music without affecting effects")
	scene.paused = false; scene.scene_index = 12; check(score.context_for(scene)=="recovery","Recovery selects a quiet emotional cue")
	scene.scene_index = 15; scene.world.player.position = Vector2(350,1030)
	check(score.context_for(scene)=="harbor","Walking onto the continuous waterfront selects its theme without reloading the map")
	scene.world.player.position = Vector2(-130,350)
	check(score.context_for(scene)=="city","Returning to the square restores its theme in the same exterior")
	scene.world.player.position = Vector2(350,1030)
	var voyage = load("res://scripts/navigation/voyage.gd").new()
	check(score.context_for(voyage).is_empty(),"Existing voyage playlist is not replaced or doubled"); voyage.free()
	var singleton = root.get_node("ChapterMusic")
	var previous_level: float = singleton.music_level
	var previous_muted: bool = singleton.muted
	scene.player_menu.switch_page("Sistema"); await frames()
	check(scene.player_menu.listing.find_child("ChapterMusicVolume",true,false)!=null,"System menu exposes the music slider")
	check(scene.player_menu.listing.find_child("ChapterMusicMute",true,false)!=null,"System menu exposes the music mute control")
	check(singleton.music_level==previous_level and singleton.muted==previous_muted,"Opening settings does not change the user's audio preferences")
	current_scene = scene; await frames()
	check(singleton.current_track=="harbor","Autoload automatically follows the active campaign scene")
	scene._begin_battle("duel"); await frames()
	check(singleton.current_track=="duel","Actual battle entry automatically switches the global soundtrack")
	scene.battle_container.hide(); await frames()
	check(singleton.current_track=="harbor","Hiding the battle automatically restores the current location theme")
	current_scene = null; await frames()
	check(singleton.current_track.is_empty(),"Leaving the chapter automatically releases its soundtrack")
	check(score.save_settings()==OK,"Audio preferences save separately from chapter progress")
	score.set_level(0.1,false); score.load_settings(); check(is_equal_approx(score.music_level,0.65),"Audio preferences restore correctly")
	if DisplayServer.get_name()!="headless":
		AudioServer.add_bus(); var bus := AudioServer.bus_count-1; AudioServer.set_bus_name(bus,"ChapterMusicQA")
		var capture := AudioEffectCapture.new(); AudioServer.add_bus_effect(bus,capture)
		for voice in score.voices: voice.bus = "ChapterMusicQA"
		score.set_context("training"); score.update_mix(2)
		var peak := 0.0
		for i in 120:
			await process_frame
			for sample in capture.get_buffer(capture.get_frames_available()): peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		check(peak>0.0001 and peak<1,"Real audio output contains non-silent music with headroom")
		for voice in score.voices: voice.stop(); voice.bus = "Master"
		AudioServer.remove_bus(bus)
	scene.free(); score.free(); await frames(2)
	if FileAccess.file_exists("res://.godot/chapter-music-test.cfg"): DirAccess.remove_absolute("res://.godot/chapter-music-test.cfg")
	print("CHAPTER_MUSIC_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"rendered":DisplayServer.get_name()!="headless"}))
	quit(0 if failures.is_empty() else 1)
