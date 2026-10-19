extends SceneTree
var Rules
const Items = preload("res://scripts/chapter/player_items.gd")
var checks := 0
var failures: Array[String] = []
var game
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures.append(message);push_error(message)
func run():
 Rules=load("res://scripts/combat/campaign_rules.gd")
 root.get_node("CampaignProfile").hero_name="Miguel"
 var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();p.flags.recovered=true
 p.vitals={"hp":23,"qi":1,"posture":17}
 var original: Dictionary=p.vitals.duplicate()
 for style in Rules.STYLES:
  var b=Rules.new();b.start_encounter("school","Miguel",style)
  check(b.units[0].hp==100 and b.units[0].posture==100 and b.units[0].qi==8,style+" gets a viable local lesson budget")
  check(p.vitals==original,"Starting a lesson cannot heal the campaign")
  b.perform(0,b.units[2].cell,1);b.end_turn(0)
  b.resolve_enemy(b.ai_plan(),{0:1});b.next_turn()
  var aim: Vector2i=b.current().cell if style=="MC" else b.units[2].cell
  check(b.valid_attack(1,aim),style+" can afford and target the taught technique with depleted campaign resources")
  b.perform(1,aim,1)
  if style=="MC": b.end_turn(0);b.resolve_enemy(b.ai_plan(),{0:1})
  check(b.lesson_result().finished,"The actual "+style+" sequence can finish")
  check(p.vitals==original,"The lesson simulation does not drain the campaign")
 var boarding=Rules.new();boarding.start_encounter("boarding","Miguel","ES")
 check(boarding.units[0].hp==23 and boarding.units[0].qi==1 and boarding.units[0].posture==17,"Real boarding still starts with actual remaining resources")
 game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();game.start_block=13;root.add_child(game)
 for i in 5: await process_frame
 p.flags.recovered=true;p.vitals=original.duplicate()
 for mode in ["school","perfect_defense","duarte_support"]:
  game.events=[{"type":"line","speaker":"Tomé","text":"Exercício concluído."}];game.event_index=-1;game.current_event={}
  game.battle_host.combat.start_encounter(mode,"Miguel","ES")
  game.battle_host.combat.units[0].hp=1;game.battle_host.combat.units[0].qi=0;game.battle_host.combat.units[0].posture=1
  game._battle_finished(true)
  check(p.vitals==original,"Completing "+mode+" preserves actual campaign resources")
 game.events=[{"type":"line","speaker":"Tomé","text":"Vamos tentar outra vez."}];game.event_index=-1;game.current_event={};game.battle_host.combat.mode="perfect_defense"
 game._battle_finished(false)
 check(p.vitals==original,"Failed defense practice also preserves personal resources")
 game._practice_aborted()
 check(p.vitals==original,"Aborting practice cannot restore or drain personal resources")
 check(p.skills.has("ES07") and p.skills.has("DP01"),"Preserving resources still grants the actual lessons")
 game._show_styles(game.style_options)
 check(game.options_box.get_child(game.options_box.get_child_count()-1).has_focus(),"A completed style focuses continuation instead of repeating the trial")
 Items.pay_service(p);Items.pay_service(p)
 check(p.coins==40,"Mandatory work pays once")
 Items.buy(p,"PT-V01");Items.buy(p,"PT-C01");Items.buy(p,"PT-C03")
 check(p.coins==7 and p.inventory["PT-V01"]==1 and p.inventory["PT-C01"]==1 and p.inventory["PT-C03"]==1,"Mandatory income covers armor and the basic kit without side requests")
 var money: int=p.coins;Items.sell(p,"PT-C01");Items.buy(p,"PT-C01")
 check(p.coins<money,"Reselling and rebuying supplies cannot generate money")
 game.phase="styles_result";game.events=[{"type":"line","speaker":"Tomé","text":"Segue caminho."}];game.event_index=-1
 p.style="ES";p.tested_styles.assign(["ES"])
 game.confirm_style()
 check(p.inventory.get("PT-W01",0)==1 and p.equipment.get("weapon","")=="PT-W01","Confirming the lesson grants the first weapon without spending money")
 var before: int=p.coins;game.phase="styles_result";game.confirm_style()
 check(p.inventory.get("PT-W01",0)==1 and p.coins==before,"Repeating confirmation cannot farm equipment or gold")
 game.queue_free()
 for i in 4: await process_frame
 print("ARC_BALANCE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
