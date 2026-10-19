extends SceneTree
const Items=preload("res://scripts/chapter/player_items.gd")
var checks:=0
var failures:Array[String]=[]
var game
var p
var prefs
func _initialize():call_deferred("run")
func frames(n:int=5):
 for i in n:await process_frame
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures.append(message);push_error(message)
func event(code:int)->InputEventKey:
 var key:=InputEventKey.new();key.physical_keycode=code;key.keycode=code;key.pressed=true;return key
func run():
 p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
 prefs=root.get_node("GamePreferences");prefs.persist_enabled=false
 root.get_node("CampaignProfile").hero_name="Miguel"
 var old:Dictionary=prefs.bindings.duplicate()
 for action in ["interact","journal","move_up","quick_save"]:
  for code in [KEY_M,KEY_B,KEY_C,KEY_V,KEY_R,KEY_SPACE]:
   check(prefs.bind_key(action,code).contains("reservada") and prefs.bindings==old,"Reserved navigation key cannot steal a fixed shortcut: "+action+"/"+str(code))
 var path:String=prefs.path;prefs.path="user://qa-old-conflict.cfg"
 var cfg:=ConfigFile.new()
 cfg.set_value("keys","interact",KEY_M);cfg.save(prefs.path)
 prefs.load_settings();prefs.apply_bindings()
 check(prefs.bindings.interact==KEY_E and not prefs.binding_notice.is_empty(),"Old conflicting interaction migrates to a safe key with visible notice")
 prefs.path=path
 check(prefs.bind_key("journal",KEY_H)=="Comando atualizado.","Notebook still accepts a free key")
 check(prefs.hint_text("J · pedidos")=="H · pedidos","Requests hint follows notebook remapping")
 prefs.bindings=prefs.DEFAULT_BINDINGS.duplicate();prefs.apply_bindings()
 game=load("res://scenes/chapter_01/plaza.tscn").instantiate();root.add_child(game);await frames()
 var before:int=p.dialogue_history.size()
 game.roam.interact("child");await frames()
 check(p.dialogue_history.size()==before+1 and p.dialogue_history.back().text==game.view.body.text,"Optional childhood dialogue is stored when displayed")
 game.free();await frames()
 var options=load("res://scripts/ui/preferences_panel.gd").new();root.add_child(options);await frames()
 var scale=options.column.get_node("TextScale");scale.grab_focus();scale.pressed.emit();await frames()
 check(root.gui_get_focus_owner()==options.column.get_node("TextScale"),"Text scaling keeps focus on the text-size control")
 var binding=options.column.get_node("Binding_combat_move");binding.grab_focus();binding.pressed.emit();await frames()
 check(root.gui_get_focus_owner()==options.column.get_node("Binding_combat_move"),"Binding capture retains its control focus")
 options._input(event(KEY_ESCAPE));await frames()
 check(options.pending_binding.is_empty() and root.gui_get_focus_owner()==options.column.get_node("Binding_combat_move"),"Cancelling a binding restores the same control")
 options.close();await frames()
 p.reset();p.flags.recovered=true;p.companion_vitals={"duarte":{"hp":110,"qi":10,"posture":100}};p.vitals={"hp":90,"qi":19,"posture":100};p.inventory["PT-C01"]=2;p.inventory["PT-C02"]=1
 var preview:Dictionary=Items.recovery_preview(p,"PT-C01","duarte")
 check(preview.hp.amount==10 and preview.hp.waste==15,"Companion preview shows exact healing and excess")
 preview=Items.recovery_preview(p,"PT-C02")
 check(preview.hp.amount==10 and preview.qi.amount==1 and preview.qi.waste==2,"Mixed recovery preview caps both resources independently")
 game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();game.start_block=13;root.add_child(game);await frames()
 p.flags.recovered=true;p.inventory["PT-C01"]=2;p.companion_vitals={"duarte":{"hp":110,"qi":10,"posture":100}}
 game._menu("Inventário");game.player_menu.select_item("PT-C01");await frames()
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.qa-runtime/review-fixes/recovery.png")
 var action:Button
 for node in game.player_menu.details.get_children():
  if node is Button and node.text=="Usar em Duarte":action=node
 check(action!=null and not action.disabled,"Lisbon inventory offers healing Duarte")
 var hero_before:Dictionary=p.vitals.duplicate()
 if action!=null:action.pressed.emit()
 check(p.companion_vitals.duarte.hp==120 and p.vitals==hero_before and p.inventory["PT-C01"]==1,"Lisbon companion action heals only Duarte and consumes one dose")
 game._menu();game.free();await frames()
 p.reset()
 var launch=load("res://scripts/navigation/voyage_launch.gd");launch.mode="test";launch.resume_requested=false
 game=load("res://scenes/navigation/voyage.tscn").instantiate();game.auto_save=false;root.add_child(game);await frames();game.set_process(false);game.clear_overlay()
 game._unhandled_input(event(KEY_M))
 check(game.overlay=="chart","M still opens the sea chart")
 game.clear_overlay()
 var previous_size:int=game.status.get_theme_font_size("font_size")
 prefs.set_text_scale(1.0 if prefs.text_scale>1.1 else 1.2);await frames()
 check(game.status.get_theme_font_size("font_size")==prefs.font_size(16) and game.status.get_theme_font_size("font_size")!=previous_size,"Existing maritime HUD updates font size immediately")
 game._unhandled_input(event(KEY_J))
 check(game.overlay=="personal","Notebook action reaches the onboard journal")
 game.clear_overlay()
 var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_Y;pad.pressed=true
 game._unhandled_input(pad)
 check(game.overlay=="chart","Controller Y keeps the sea chart instead of being intercepted by the notebook")
 game.clear_overlay();prefs.bind_key("journal",KEY_H)
 game._unhandled_input(event(KEY_H))
 check(game.overlay=="personal","Rebound notebook key opens the actual onboard journal")
 game.clear_overlay();game._unhandled_input(event(KEY_J))
 check(game.overlay.is_empty(),"Old notebook key no longer opens the journal after remapping")
 game.free();await frames();prefs.bindings=prefs.DEFAULT_BINDINGS.duplicate();prefs.apply_bindings();prefs.set_text_scale(1)
 if FileAccess.file_exists("user://qa-old-conflict.cfg"):DirAccess.remove_absolute("user://qa-old-conflict.cfg")
 print("REVIEW_FIXES_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
