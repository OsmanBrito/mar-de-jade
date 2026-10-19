extends SceneTree
const Items = preload("res://scripts/chapter/player_items.gd")
const Kit = preload("res://scripts/navigation/boarding_loadout.gd")
var Rules
var checks := 0
var failures: Array[String] = []
var results: Array = []
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures.append(message);push_error(message)
func battle(style: String):
 var p=root.get_node("ChapterProgress")
 p.reset();p.auto_save=false;p.flags.recovered=true;p.style=style
 p.tested_styles.assign([style]);p.skills.assign([Rules.FIRST[style],"DU01","DP01"])
 p.flags.perfect_defense=true
 Items.pay_service(p)
 for id in Items.items():
  var row: Dictionary=Items.items()[id]
  if id.begins_with("PT-") and row.get("style","")==style:
   p.inventory[id]=1;Items.equip(p,id);break
 for id in ["PT-V01","PT-C01","PT-C03"]: Items.buy(p,id)
 Items.equip(p,"PT-V01")
 # Equipping never heals; entering this probe with the actual base vitals.
 var b=Rules.new();b.progress_override=Kit.capture(p.snapshot());b.start_encounter("boarding","Miguel",style)
 return b
func fight(b) -> Dictionary:
 var turns:=0
 for i in 160:
  if not b.outcome().is_empty():break
  turns+=1
  if b.current().team==0:
   var target:=-1;var nearest:=999
   for enemy in b.enemies:
    if enemy.hp>0 and b.distance(b.current().cell,enemy.cell)<nearest:
     target=enemy.id;nearest=b.distance(b.current().cell,enemy.cell)
   if target<0:break
   var aim: Vector2i=b.units[target].cell
   if not b.valid_attack(0,aim):
    var best: Vector2i=b.current().cell;var score:=999
    for cell in b.reachable(b.current_id).costs:
     var distance: int=b.distance(cell,aim)
     if distance<score:best=cell;score=distance
    b.move_to(best)
   if b.valid_attack(0,aim):b.perform(0,aim,1)
   b.end_turn(b.suggested_facing(b.current_id))
  else:
   b.resolve_enemy(b.ai_plan(),{0:1,1:1});b.next_turn()
 return {"style":b.style,"outcome":b.outcome(),"turns":turns,"hero_hp":b.units[0].hp,"duarte_hp":b.units[1].hp}
func run():
 Rules=load("res://scripts/navigation/boarding_rules.gd")
 root.get_node("CampaignProfile").hero_name="Miguel"
 var p=root.get_node("ChapterProgress")
 for style in Rules.STYLES:
  var b=battle(style)
  check(p.coins==7,style+": compulsory income covers protection and both combat supplies")
  check(b.units[0].defense==2 and b.units[0].max_hp==112,style+": bought protection reaches real boarding")
  check(b.commands(0)==[0,1,-1] and not b.commands(0).has(2),style+": only learned technique, no demo exercises aboard")
  var result:=fight(b);results.append(result)
  check(result.outcome=="victory",style+": first boarding is winnable with ordinary timing and no optional rewards")
  b=battle(style);b.current_id=0;b.units[0].cell=Vector2i(2,2);b.units[2].cell=Vector2i(3,2)
  b.units[2].hp=300;b.units[2].max_hp=300
  b.units[0].qi=0
  check(not b.availability_reason(1).is_empty(),style+": cannot spend unavailable energy")
  var before: int=b.units[0].qi
  var expected: Dictionary=b.predict(0,2,0,1)
  var hp_before: int=b.units[2].hp
  var posture_before: int=b.units[2].posture
  var hit: Dictionary=b.perform(0,b.units[2].cell,1)
  check(hp_before-b.units[2].hp==expected.damage and posture_before-b.units[2].posture==expected.posture,style+": actual damage and posture match tactical preview")
  check(not hit.has("error") and b.units[0].qi==before+1,style+": basic remains viable at zero energy")
  b.units[0].acted=false;b.units[0].qi=20
  if style=="LA":
   check(not b.valid_attack(1,b.units[2].cell),"Lance foundation rejects adjacent targets")
   b.units[2].cell=Vector2i(4,2)
  if style=="FO":
   b.units[2].cell=Vector2i(4,2)
   b.obstacles.append(Vector2i(3,2))
   check(not b.valid_attack(1,b.units[2].cell),"Firearm foundation cannot shoot through obstacles")
   b.obstacles.erase(Vector2i(3,2))
   b.units[2].cell=Vector2i(3,3)
   check(not b.valid_attack(1,b.units[2].cell),"Firearm foundation rejects diagonal aim")
   b.units[2].cell=Vector2i(4,2)
  var aim: Vector2i=b.current().cell if style=="MC" else b.units[2].cell
  check(b.valid_attack(1,aim),style+": learned foundation has a valid target")
  var cost: int=b.skill_def(0,1).cost;before=b.units[0].qi
  hit=b.perform(1,aim,1)
  check(not hit.has("error") and b.units[0].qi==before-cost,style+": execution charges displayed energy")
 var b=battle("ES");b.current_id=0
 b.units[0].qi=19
 var preview: Dictionary=b.support_preview(0,7,b.units[0].cell)
 check(preview.amount==1 and preview.qi==1 and preview.waste==4,"Water preview consistently reports actual recovery and excess")
 var initial: int=b.progress_override.inventory["PT-C03"]
 b.perform(7,b.units[0].cell,1)
 check(b.units[0].qi==20 and b.progress_override.inventory.get("PT-C03",0)==initial-1,"Water restores only deficit and consumes one personal unit")
 b.units[0].acted=false
 check(not b.valid_attack(6,b.units[1].cell) or b.units[1].hp<b.units[1].max_hp,"Full allies cannot waste bandages")
 b.units[0].hp=90;b.units[0].acted=false
 preview=b.support_preview(0,6,b.units[0].cell)
 check(preview.amount==22 and preview.hp==22 and preview.waste==3,"Bandage preview shows exact life and waste with purchased armor")
 b.perform(6,b.units[0].cell,1)
 check(b.units[0].hp==112 and b.progress_override.inventory.get("PT-C01",0)==0,"Bandage execution matches preview and consumes only one unit")
 b=battle("ES")
 p.tested_styles.assign(["ES","MC","PU"]);p.inventory["PT-W03"]=1;p.inventory["PT-W05"]=1
 var delta: Dictionary=Items.comparison(p,"PT-W03")
 check(delta.power==7,"Cross-style comparison includes axe base power and weapon bonus")
 Items.equip(p,"PT-W03")
 check(Items.comparison(p,"PT-W05").power==-13,"Unarmed comparison includes loss of axe base power and bonus")
 p.inventory["PT-C02"]=1;p.vitals={"hp":80,"qi":18,"posture":100}
 Items.use(p,"PT-C02")
 check(p.vitals.hp==95 and p.vitals.qi==20 and p.inventory.get("PT-C02",0)==0,"Ration restores both resources with caps outside combat")
 for id in Items.items():
  if not id.begins_with("FERRO:"):continue
  var row: Dictionary=Items.items()[id]
  check(row.price>0 and row.stock>0 and row.slot in Items.SLOTS,"Imported equipment has bounded Jade price, stock and supported slot: "+id)
 var game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
 game.start_block=13;root.add_child(game)
 for i in 5:await process_frame
 p.flags.recovered=true;p.tested_styles.assign(["ES","MC"]);p.inventory["PT-W01"]=1;p.inventory["PT-W03"]=1
 p.style="ES";p.equipment={"weapon":"PT-W01"}
 game._menu("Equipamento");game.player_menu.select_item("PT-W03")
 var text:=""
 for child in game.player_menu.details.get_children():
  if child is Label:text+=child.text+"\n"
 check(text.contains("Potência do básico +7") and text.contains("alcance do básico: 1"),"Actual inventory displays cross-style power and basic range")
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.qa-runtime/balance-close/equipment.png")
 game.queue_free()
 for i in 3:await process_frame
 print("COMBAT_ECONOMY_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"boarding":results}))
 quit(0 if failures.is_empty() else 1)
