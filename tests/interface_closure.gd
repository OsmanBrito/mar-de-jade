extends SceneTree
const Log = preload("res://scripts/chapter/dialogue_log.gd")
var View
const Launch = preload("res://scripts/navigation/voyage_launch.gd")
var checks := 0
var failures: Array[String] = []
var game
var p
var prefs
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures.append(message);push_error(message)
func frames(n: int = 5):
 for i in n:await process_frame
func pad(code: int):
 var event:=InputEventJoypadButton.new();event.button_index=code;event.pressed=true;root.push_input(event);await frames()
 event.pressed=false;root.push_input(event);await frames()
func capture(name: String):
 if DisplayServer.get_name()=="headless":return
 if is_instance_valid(game) and game.get("host")!=null:game.host.queue_redraw()
 await frames(8);await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://.qa-runtime/interface-close/"+name+".png")
func run():
 root.size=Vector2i(960,600)
 View=load("res://scripts/chapter/dialogue_view.gd")
 p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
 prefs=root.get_node("GamePreferences");prefs.persist_enabled=false
 root.get_node("CampaignProfile").hero_name="Miguel"
 var view=View.new();root.add_child(view);await frames()
 view.remember("Tomé","Uma fala vista.");view.remember("Tomé","Uma fala vista.")
 check(p.dialogue_history.size()==1,"Repeated rendering does not duplicate the same dialogue")
 view.free()
 view=View.new();root.add_child(view);await frames()
 check(view.history.size()==1,"A new scene view reads the same transcript")
 var saved: Dictionary=p.snapshot()
 check(saved.schema_version==13 and saved.dialogue_history.size()==1,"Version 13 save contains the transcript and character development")
 check(p.save_to("user://qa-interface.json")==OK,"Transcript saves through actual chapter writer")
 p.reset();check(p.load_from("user://qa-interface.json")==OK and p.dialogue_history.size()==1,"Disk load restores viewed lines")
 var stable: Dictionary=p.snapshot()
 for bad in [null,{},[{"speaker":"Tomé","text":5}],[{"speaker":"","text":"Invalid"}]]:
  var invalid: Dictionary=stable.duplicate(true);invalid.dialogue_history=bad
  check(p.restore(invalid)==ERR_INVALID_DATA and p.snapshot()==stable,"Malformed transcript rejects atomically")
 var old: Dictionary=stable.duplicate(true);old.schema_version=10;old.erase("dialogue_history")
 check(p.restore(old)==OK and p.dialogue_history.is_empty(),"Old version 10 migrates with no invented dialogue")
 for i in 205:Log.remember(p,"Tomé","Fala "+str(i))
 check(p.dialogue_history.size()==200 and p.dialogue_history[0].text=="Fala 5","Transcript keeps only the last 200 viewed lines")
 p.reset();check(p.dialogue_history.is_empty(),"New campaign clears previous dialogue")
 view.free()
 game=load("res://scenes/chapter_01/opening.tscn").instantiate();root.add_child(game);await frames()
 check(not p.dialogue_history.is_empty(),"Actual opening records only a displayed line")
 var first: Dictionary=p.dialogue_history[0].duplicate()
 var menu=game.get_node("ChildhoodMenu");menu.open("history");await frames()
 check(menu.opened and paused,"Childhood conversations use the shared pause")
 var cursor: int=game.event_index
 menu.settings();await frames()
 var settings=menu.get_child(menu.get_child_count()-1)
 check(settings.column.has_node("Binding_move_left") and settings.column.has_node("Binding_combat_timing"),"All movement and combat bindings are available in childhood preferences")
 settings.column.get_node("Binding_combat_move").pressed.emit();await frames()
 var original: int=prefs.bindings.combat_move
 await pad(JOY_BUTTON_B)
 check(menu.settings_open and settings.pending_binding.is_empty() and prefs.bindings.combat_move==original,"B cancels a pending remap without closing settings")
 await pad(JOY_BUTTON_B)
 check(menu.opened and paused and not menu.settings_open,"B returns from settings to the paused notebook")
 menu.close();check(not paused and game.event_index==cursor,"Resuming never advances the narrative")
 game.free();await frames()
 p.flags={};p.entry_scene="res://scenes/chapter_01/plaza.tscn"
 game=load("res://scenes/chapter_01/plaza.tscn").instantiate();root.add_child(game);await frames()
 check(p.dialogue_history.has(first),"Opening conversation survives the change to the plaza")
 game.free();await frames()
 prefs.set_text_scale(1.2)
 prefs.controller=true
 var hint: String=prefs.navigation_hint("W ↑ vela · S ↓ vela · A/D leme | Espaço parar | M carta · C convés · V retomar rumo · E / A interagir")
 check(hint.contains("RB parar") and hint.contains("LB retomar rumo") and hint.contains("Y carta") and not hint.contains("A parar"),"Sea hints match actual controller stop, resume and chart buttons")
 check(prefs.navigation_hint("Bombordo · Q | Boreste · E | Ordens · Espaço",true).contains("Ordens · Y"),"Naval orders use Y, not generic combat A")
 prefs.controller=false
 check(prefs.bind_key("move_up",KEY_I)=="Comando atualizado.","Movement binding can change")
 check(prefs.navigation_hint("W ↑ vela · S ↓ vela · A/D leme").begins_with("I ↑"),"Sea movement hint follows the rebound sail key")
 var childhood_history: Array=p.dialogue_history.duplicate(true)
 p.reset();p.dialogue_history.assign(childhood_history)
 p.completed=true;p.checkpoint=16;p.entry_scene="res://scenes/chapter_01/chapter_flow.tscn";p.flags={"recovered":true,"embarked":true}
 p.vitals={"hp":100,"qi":20,"posture":100}
 Launch.mode="campaign";Launch.resume_requested=false
 game=load("res://scenes/navigation/voyage.tscn").instantiate();game.auto_save=false;root.add_child(game);await frames();game.set_process(false);game.clear_overlay()
 var before: int=p.dialogue_history.size()
 game.show_conversation("Duarte","Esta fala é nova e só aparece agora.")
 check(p.dialogue_history.size()==before+1 and game.model.campaign_state.dialogue_history==p.dialogue_history,"New ship conversation joins the carried campaign transcript")
 game.save_path="user://qa-interface-voyage.json"
 game.model.phase="sea";game.clear_overlay()
 check(game.model.save_to(game.save_path)==OK,"Voyage save accepts the version 12 transcript")
 var saved_history: Array=p.dialogue_history.duplicate(true)
 game.model.campaign_state.dialogue_history=[]
 check(game.model.load_from(game.save_path)==OK and game.model.campaign_state.dialogue_history==saved_history,"Voyage load retains both land and ship conversations")
 game.open_conversations();await frames(12)
 var panels: Array=game.modal_root.find_children("*","PanelContainer",true,false)
 check(not panels.is_empty() and panels[0].get_global_rect().end.x<=root.get_visible_rect().size.x and panels[0].get_global_rect().end.y<=root.get_visible_rect().size.y,"Ship conversations fit small window with 120 percent text")
 await capture("ship-history")
 game.open_pause();game.open_preferences();await frames()
 check(paused,"Shared ship preferences pause simulation")
 var shared=game.get_child(game.get_child_count()-1)
 check(shared.sheet.get_global_rect().end.y<=root.get_visible_rect().size.y,"Shared settings remain inside the viewport at 120 percent text")
 await capture("shared-settings")
 await pad(JOY_BUTTON_B)
 check(not paused and game.overlay=="pause","Closing preferences returns to the voyage pause")
 prefs.set_level("effects",0);prefs.set_level("ambience",0);prefs.set_music_muted(true)
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index(prefs.effects_bus)) and AudioServer.is_bus_mute(AudioServer.get_bus_index(prefs.ambience_bus)),"Mute settings reach actual effects and ambience buses")
 check(root.get_node("ChapterMusic").muted and (DisplayServer.get_name()=="headless" or AudioServer.is_bus_mute(AudioServer.get_bus_index(game.ambience.buses.music))),"Music mute reaches both chapter and navigation mixers")
 game.free();await frames()
 game=load("res://scenes/art/combat_study.tscn").instantiate();game.encounter="school";game.style="ES";root.add_child(game);await frames()
 game.host.set_process(false)
 var b=game.host.combat;var tactical=game.host.tactical
 tactical.select_skill(0);tactical.select_cell(b.units[2].cell);tactical.confirm()
 check(tactical.phase=="timing_attack" and not tactical.timing_title().is_empty(),"Silent combat retains a visible timing objective")
 await capture("silent-timing")
 tactical.commit_timing(1);tactical.update(0.451)
 check(not tactical.result.is_empty() and not tactical.result.text.is_empty() and not tactical.result.hits.is_empty(),"Silent combat retains textual and numerical hit feedback")
 game.free();await frames()
 prefs.set_level("effects",0.85);prefs.set_level("ambience",0.85);prefs.set_music_muted(false)
 prefs.set_text_scale(1);prefs.bindings=prefs.DEFAULT_BINDINGS.duplicate();prefs.apply_bindings()
 for path in ["user://qa-interface.json","user://qa-interface.json.bak","user://qa-interface-voyage.json","user://qa-interface-voyage.json.bak"]:
  if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
 print("INTERFACE_CLOSURE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
