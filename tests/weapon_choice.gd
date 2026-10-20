extends SceneTree
const Weapons=preload("res://scripts/chapter/weapon_choices.gd")
const Launch=preload("res://scripts/navigation/voyage_launch.gd")
var checks:=0
var failures:Array[String]=[]
var game
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures.append(message);push_error(message)
func frames(n:int=4):
 for i in n:await process_frame
func capture(name:String):
 if DisplayServer.get_name()=="headless":return
 await frames(10);await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://.qa-runtime/weapon-choice/"+name+".png")
func accept():
 var event:=InputEventAction.new();event.action="ui_accept";event.pressed=true;root.push_input(event);await frames()
 event.pressed=false;root.push_input(event);await frames()
func run():
 root.size=Vector2i(1280,800)
 var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
 root.get_node("CampaignProfile").hero_name="Miguel"
 root.get_node("GamePreferences").persist_enabled=false
 p.flags={"recovered":true,"patient_helped":true}
 p.tested_styles.assign(["ES","LA","PU"]);p.inventory["PT-W01"]=1;p.inventory["PT-W02"]=1
 p.equipment.weapon="PT-W01";p.vitals={"hp":75,"qi":8,"posture":80}
 game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();game.start_block=3;root.add_child(game);await frames()
 game.phase="exploration";game.busy=false;game._menu("Personagem");await frames()
 var menu=game.player_menu
 check(menu.listing.get_child(1) is Button and menu.listing.get_child(1).text=="Escolher arma do herói","The character page offers weapon choice as its first action")
 menu.listing.get_child(1).pressed.emit();await frames()
 check(menu.page=="Armas" and menu.row_buttons.size()==5,"The direct action opens the five weapon families without clothes or story items")
 check(menu.action_button.disabled and menu.action_button.text=="Em uso no herói","Current weapon is explicit and cannot be equipped twice")
 var before:Dictionary=p.snapshot()
 menu.row_buttons["PT-W02"].pressed.emit();await frames()
 check(p.snapshot()==before,"Previewing a different weapon does not silently equip it")
 check(root.gui_get_focus_owner()==menu.action_button and menu.action_button.text=="Equipar no herói","Selecting a weapon focuses the visible confirmation")
 await accept()
 check(p.style=="LA" and p.equipment.weapon=="PT-W02" and p.vitals==before.vitals,"Keyboard confirmation equips the hero without recovering resources")
 check(menu.action_button.disabled and menu.notice.text.contains("Equipado"),"Confirmation updates the current marker and gives feedback")
 await capture("land-weapons")
 menu.row_buttons["PT-W03"].pressed.emit();await frames()
 check(menu.action_button.text=="Ver armas na loja" and not p.inventory.has("PT-W03"),"Missing weapons are distinguished from owned weapons without granting free items")
 menu.action_button.pressed.emit();await frames()
 check(menu.page=="Loja de Lisboa" and menu.filter=="Armas","Buying follows a direct weapon-filtered shop route")
 check(menu.row_buttons.keys().all(func(id):return Weapons.Items.items()[id].slot=="weapon"),"The weapon shop route excludes supplies and clothing")
 menu.switch_page("Armas");p.inventory["PT-W03"]=1;menu.select_weapon("PT-W03");await frames()
 check(menu.action_button.disabled,"An owned but untrained weapon keeps the existing learning requirement")
 menu.select_weapon(Weapons.UNARMED);await frames();menu.action_button.pressed.emit();await frames()
 check(p.style=="PU" and not p.equipment.has("weapon") and p.inventory["PT-W02"]==1,"Desarmado is an explicit choice and retains the owned weapon")
 root.size=Vector2i(960,600);root.get_node("GamePreferences").set_text_scale(1.2);menu.refresh();await frames()
 check(menu.action_button.get_global_rect().end.x<=root.get_visible_rect().size.x and menu.action_button.get_global_rect().end.y<=root.get_visible_rect().size.y,"The primary weapon action fits the small window with enlarged text")
 await capture("land-small")
 game._menu();await frames()
 var lesson_options:Array=[]
 for block in game.blocks:
  for event in block.events:
   if event.type=="styles" and lesson_options.is_empty():lesson_options=event.options
 var before_lesson:Dictionary=p.snapshot()
 game._show_styles(lesson_options);await frames()
 check(game.lesson_choice.cards.size()==5 and game.lesson_choice.primary.disabled,"Tomé presents five illustrated choices and waits for an explicit selection")
 game.lesson_choice.cards["LA"].pressed.emit();await frames()
 check(p.snapshot()==before_lesson and game.lesson_choice.primary.text=="Escolher Lança como arma do herói","The mission previews the chosen weapon without starting a test")
 check(game.lesson_choice.primary.get_global_rect().end.y<=root.get_visible_rect().size.y,"The mission confirmation fits the small window with large text")
 game._free_practice_menu();await frames()
 check(game.view.panel.visible and not game.lesson_choice.screen.visible,"Optional practice remains visible after leaving the dedicated choice screen")
 game._show_styles(lesson_options);game.lesson_choice.select("LA");await frames()
 await capture("tome-choice")
 game.lesson_choice.primary.pressed.emit();await frames()
 check(not game.lesson_choice.screen.visible and p.style=="LA" and p.equipment.weapon=="PT-W02" and game.phase!="battle","Confirming equips the chosen weapon without starting a test")
 game._style_result();await frames()
 check(game.options_box.get_child(0).text.begins_with("Ficar com") and root.gui_get_focus_owner()==game.options_box.get_child(0),"Lesson completion prioritizes choosing the weapon instead of optional passives")
 for style in ["ES","LA","MC","FO","PU"]:
  p.reset();p.flags.recovered=true
  game.events=[{"type":"styles","options":lesson_options},{"type":"line","speaker":"Tomé","text":"Arma escolhida. Podemos continuar."}];game.event_index=0
  game._show_styles(lesson_options);game.lesson_choice.select(style);game.lesson_choice.primary.pressed.emit();await frames()
  var item:String=game.lesson_choice.FIRST[style]
  check(p.style==style and p.equipment.weapon==item and p.inventory[item]==1,"Direct choice gives and equips exactly the selected weapon: "+style)
  check(p.skills.has(game.RULES.FIRST[style]) and p.tested_styles==[style],"Direct choice teaches only the selected foundation: "+style)
  if style=="FO":check(game.RULES.Firearm.LEARNED.all(func(id):return p.skills.has(id)),"Tomé teaches all four firearm techniques on direct weapon choice")
  check(game.phase=="dialogue" and game.current_event.text=="Arma escolhida. Podemos continuar." and game.events.size()==2,"The mission continues without injecting test fights: "+style)
  var received:Dictionary=p.snapshot()
  game._choose_lesson_weapon(style)
  check(p.snapshot()==received,"Repeated input cannot duplicate the gift: "+style)
 game.free();await frames()
 p.completed=true;p.checkpoint=16;p.entry_scene="res://scenes/chapter_01/chapter_flow.tscn";p.flags.embarked=true;p.flags.packed=true
 p.style="ES";p.equipment.weapon="PT-W01";p.inventory["PT-W01"]=1;p.inventory["PT-W02"]=1
 p.tested_styles.assign(["ES","LA","PU"])
 Launch.mode="campaign";Launch.resume_requested=false
 game=load("res://scenes/navigation/voyage.tscn").instantiate();game.auto_save=false;root.add_child(game);await frames();game.set_process(false);game.clear_overlay();game.model.dock("lisboa")
 game.open_personal("weapons");await frames()
 check(game.overlay=="personal","The ship has its own direct hero weapon screen")
 var fund:int=game.model.coins
 game.personal_action("weapon","PT-W02");await frames()
 check(p.style=="LA" and game.model.boarding_profile.equipment.weapon=="PT-W02" and game.model.coins==fund,"Ship weapon choice updates the boarding profile without spending crew money")
 await capture("ship-weapons")
 game.model.phase="naval"
 game.personal_action("weapon","PT-W01");await frames()
 check(game.model.boarding_profile.equipment.weapon=="PT-W02","Unsafe phases cannot bypass equipment restrictions")
 game.free();await frames()
 print("WEAPON_CHOICE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
