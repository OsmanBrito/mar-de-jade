extends SceneTree
const Items=preload("res://scripts/chapter/player_items.gd")
const Kit=preload("res://scripts/navigation/boarding_loadout.gd")
var Rules
var checks:=0
var failures:Array[String]=[]
var results:Array=[]
func _initialize():call_deferred("run")
func check(ok:bool,text:String):
 checks+=1
 if not ok:failures.append(text);push_error(text)
func make(style:String,variant:String):
 var p=root.get_node("ChapterProgress");p.reset();p.auto_save=false;p.style=style;p.flags.recovered=true
 p.tested_styles.assign([style]);p.skills.assign([Rules.FIRST[style],"DU01","DP01"]);p.flags.perfect_defense=true
 for id in Items.items():
  if id.begins_with("PT-") and Items.items()[id].get("style","")==style:p.inventory[id]=1;Items.equip(p,id);break
 Items.pay_service(p)
 var outfit: String="PT-V02" if variant=="capa" else "PT-V03" if variant=="botas" else "PT-V01"
 for id in [outfit,"PT-C01","PT-C03"]:Items.buy(p,id)
 Items.equip(p,outfit);p.vitals.qi=0 if variant=="low_qi" else 20
 if variant=="wounded":p.companion_vitals={"duarte":{"hp":35,"qi":0,"posture":40}}
 var b=Rules.new();b.progress_override=Kit.capture(p.snapshot());b.start_encounter("boarding","Miguel",style)
 return b
func fight(b,tactical:bool,quality:int)->Dictionary:
 var ticks:=0;var techniques:=0;var items:=0
 for i in 200:
  if not b.outcome().is_empty():break
  ticks+=1
  if b.current().team!=0:
   b.resolve_enemy(b.ai_plan(),{0:quality,1:quality});b.next_turn();continue
  var target:=-1;var near:=999
  for enemy in b.enemies:
   if enemy.hp>0 and b.distance(b.current().cell,enemy.cell)<near:target=enemy.id;near=b.distance(b.current().cell,enemy.cell)
  if target<0:break
  var aim:Vector2i=b.units[target].cell
  var skill:=0
  if tactical and b.current_id==0 and b.previous_action==0 and b.availability_reason(1).is_empty():skill=1
  if tactical and b.current().hp<b.current().max_hp*.5 and b.valid_attack(6,b.current().cell):
   b.perform(6,b.current().cell,1);items+=1;b.end_turn(b.suggested_facing(b.current_id));continue
  if skill==1 and b.style=="MC":aim=b.current().cell
  else:
   var origin:Vector2i=b.current().cell
   var best:Vector2i=origin;var score:=-10000.0
   for cell in b.reachable(b.current_id).costs:
    b.current().cell=cell
    var valid:bool=b.valid_attack(skill,aim)
    var distance:float=b.distance(cell,aim)
    var value:float=1000.0 if valid else 0.0
    value+=(distance if tactical and b.current_id==0 and b.style in ["FO","LA"] and valid else -distance)
    value-=origin.distance_to(cell)*.01
    if value>score:best=cell;score=value
   b.current().cell=origin
   if best!=origin:b.move_to(best)
  if not b.valid_attack(skill,aim):skill=0;aim=b.units[target].cell
  if b.valid_attack(skill,aim):
   var hit:Dictionary=b.perform(skill,aim,quality)
   if not hit.has("error") and skill==1:techniques+=1
  b.end_turn(b.suggested_facing(b.current_id))
 return {"style":b.style,"result":b.outcome(),"ticks":ticks,"hero_hp":b.units[0].hp,"duarte_hp":b.units[1].hp,"techniques":techniques,"consumables":items}
func run():
 Rules=load("res://scripts/navigation/boarding_rules.gd");root.get_node("CampaignProfile").hero_name="Miguel"
 for style in Rules.STYLES:
  for variant in ["normal","missed","low_qi","wounded","tactical","capa","botas"]:
   var b=make(style,variant);var result:=fight(b,variant=="tactical",0 if variant=="missed" else 1)
   result.variant=variant;results.append(result)
   check(not result.result.is_empty(),style+"/"+variant+": real AI encounter terminates")
   var valid:=true
   for unit in b.units:
    for key in ["hp","qi","posture"]:
     if unit[key]<0 or unit[key]>unit["max_"+key]:valid=false
   check(valid,style+"/"+variant+": resources remain within real character limits")
   if variant in ["normal","low_qi","tactical","capa","botas"]:check(result.result=="victory",style+"/"+variant+": required income supports a viable first approach")
 print("COMBAT_STRESS_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"encounters":results}))
 quit(0 if failures.is_empty() else 1)
