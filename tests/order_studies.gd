extends SceneTree
var Rules
const Studies=preload("res://scripts/combat/order_studies.gd")
var checks:=0
var failures: Array[String]=[]
var p
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok:failures.append(message);push_error(message)
func fresh(style: String):
	p.reset();p.style=style;p.tested_styles.append(style);p.learn(Rules.FIRST[style]);p.learn(Studies.IDS[style])
	var c=Rules.new();c.start_encounter("practice","Miguel",style);c.obstacles.clear()
	c.current_id=0;c.units[0].cell=Vector2i(4,3);c.units[0].turn_origin=c.units[0].cell;c.units[0].qi=40;c.units[0].acted=false;c.units[0].moves=5;c.units[0].face=0
	c.units[2].cell=Vector2i(5,3);c.units[2].kind="defender";c.units[2].guard=false;c.units[2].face=2
	for i in range(3,c.units.size()):c.units[i].hp=0;c.units[i].withdrawn=true
	return c
func plan(c) -> Dictionary:return {"kind":"attack","power":30,"posture":10,"cells":[c.units[0].cell],"targets":[0],"path":[],"destination":c.units[2].cell,"name":"Contacto físico"}
func run():
	Rules=load("res://scripts/combat/campaign_rules.gd")
	p=root.get_node("ChapterProgress");p.auto_save=false;root.get_node("GamePreferences").persist_enabled=false
	for style in Studies.IDS:
		var c=fresh(style);var id: String=Studies.IDS[style]
		check(c.commands(0).has(100),style+" learned and prepared study becomes a command")
		check(c.skill_def(0,100).content_id==id and c.skill_def(0,100).cost==Studies.COSTS[id],style+" runtime definition uses real catalogue ID and cost")
		p.development.members.hero.active_skills.erase(id)
		check(not c.commands(0).has(100),style+" unprepared study is unavailable")
		p.development.members.hero.active_skills.append(id)
		var aim: Vector2i=c.units[0].cell if style=="ES" else Vector2i(4,4) if style=="PU" else c.units[2].cell
		var snapshot: Dictionary=p.snapshot();var qi: int=c.units[0].qi;var origin: Vector2i=c.units[0].cell
		var hp: int=c.units[2].hp
		var prediction: Dictionary=c.predict(0,2,100,1,aim) if style in ["LA","MC","FO"] else {}
		var result: Dictionary=c.perform(100,aim,1)
		check(not result.has("error"),style+" study executes a real legal action: "+str(result.get("error","")))
		check(c.units[0].qi==qi-Studies.COSTS[id] and c.units[0].acted,style+" pays alento and one main action")
		check(p.snapshot()==snapshot,style+" combat action does not alter personal resources")
		if style in ["LA","MC","FO"]:check(hp-c.units[2].hp==prediction.damage,style+" predicted damage equals real impact")
		if style in ["LA","MC"]:
			check(c.units[0].cell!=origin and c.distance(origin,c.units[0].cell)==1,style+" lateral step occurs after damage")
			c=fresh(style);c.obstacles.assign([Vector2i(4,2),Vector2i(4,4)])
			check(not c.attack_reason(100,c.units[2].cell).is_empty(),style+" blocked lateral destinations reject the action")
			var before: Dictionary=c.units[0].duplicate(true);result=c.perform(100,c.units[2].cell,1)
			check(result.has("error") and c.units[0]==before,style+" illegal study consumes no action, movement or resources")
		if style=="ES":
			check(not c.units[0].guard,"ES09 has custom protection without inherited 50 percent guard")
			check(c.defense_preview(2,0,plan(c),0).get("order_guard_used",false),"ES09 protects original front")
			c.units[2].cell=Vector2i(4,4)
			check(c.defense_preview(2,0,plan(c),0).get("order_guard_used",false),"ES09 protects chosen right side")
			c.units[2].cell=Vector2i(4,2)
			check(not c.defense_preview(2,0,plan(c),0).get("order_guard_used",false),"ES09 leaves left and rear unprotected")
			c.units[2].cell=Vector2i(5,3);c.current_id=2;c.resolve_enemy(plan(c),{0:0})
			check(c.order_guard.is_empty(),"ES09 consumes protection on one eligible attack")
		if style=="PU":
			check(result.hits.is_empty() and c.units[0].moves==4 and hp==c.units[2].hp,"PU09 is movement/protection only, without damage or free movement")
			c.units[2].cell=Vector2i(5,4)
			check(c.defense_preview(2,0,plan(c),0).get("order_guard_used",false),"PU09 protects old frontal direction after moving")
			c=fresh(style);c.units[0].moves=0
			check(not c.attack_reason(100,Vector2i(4,4)).is_empty(),"PU09 respects exhausted movement budget")
		if style=="MC":
			c=fresh(style);c.perform(100,c.units[2].cell,1)
			check(c.order_exposed_face==0 and c.defense_preview(2,0,plan(c),0).get("order_exposure_used",false),"MC09 exposes old frontal direction after the step")
		if style=="FO":
			check(c.units[2].get("order_disarmed",false),"FO10 Good hit disarms eligible ordinary weapon")
			c.current_id=2;var intent: Dictionary=c.ai_plan()
			check(intent.get("order_disarm_recovery",false) and intent.targets.is_empty(),"Disarmed enemy spends its next action restoring grip")
			c.resolve_enemy(intent,{})
			check(not c.units[2].get("order_disarmed",false),"Grip recovery clears disarm")
			c.current_id=0;c.units[0].acted=false;c.units[0].qi=40;c.units[2].turns=1;c.perform(100,c.units[2].cell,1)
			check(not c.units[2].get("order_disarmed",false),"Temporary immunity prevents repeated action denial")
			c=fresh(style);c.perform(100,c.units[2].cell,0)
			check(not c.units[2].get("order_disarmed",false),"Failed timing preserves damage but grants no disarm")
			c=fresh(style);c.units[2].kind="boss";c.perform(100,c.units[2].cell,1)
			check(c.units[2].get("order_weapon_weakened",false) and not c.units[2].get("order_disarmed",false),"Boss receives power reduction instead of losing action")
			c=fresh(style);c.units[2].kind="animal";c.perform(100,c.units[2].cell,1)
			check(not c.units[2].get("order_disarmed",false),"Animal without physical weapon cannot be disarmed")
			c=fresh(style);c.units[2].physical_weapon=false;c.perform(100,c.units[2].cell,1)
			check(not c.units[2].get("order_disarmed",false),"Projection-only adversary is not disarmed")
		# The same real orientation exercise is solvable with each supported weapon.
		c=fresh(style);c.mode="order_trial";c.lesson=1;c.valid_hits=0;c.units[2].cell=Vector2i(4,6)
		c.move_to(Vector2i(4,4));c.move_to(Vector2i(4,5));c.perform(0,c.units[2].cell,1);c.units[0].face=1;c.current_id=2
		c.resolve_enemy(c.ai_plan(),{0:1})
		check(c.lesson_result().finished and c.lesson_result().success,style+" solves position, real hit and Good frontal response")
		c=fresh(style);c.mode="boarding";p.equipped_passives.assign(["GE22"]);c.previous_action=0;c.previous_action_turn=c.units[0].turns-1
		check(c.skill_def(0,100).cost==Studies.COSTS[id]-1,style+" study respects first-technique passive discount")
		var discount_aim: Vector2i=c.units[0].cell if style=="ES" else Vector2i(4,4) if style=="PU" else c.units[2].cell
		var discount_qi: int=c.units[0].qi;c.perform(100,discount_aim,1)
		check(c.technique_evaluated and c.units[0].qi==discount_qi-Studies.COSTS[id]+1,style+" spends and consumes the real discounted technique")
	# UI preparation actions must not require offensive timing.
	var c=fresh("PU")
	var host=load("res://scripts/combat/battle_host.gd").new();host.combat=c;root.add_child(host)
	host.active=false;host.tactical.begin();host.tactical.phase="aim";host.tactical.selected_skill=100;host.tactical.selected_cell=Vector2i(4,4)
	host.tactical.confirm()
	check(host.tactical.phase!="timing_attack" and host.tactical.phase.begins_with("animate"),"PU09 confirmation goes directly to animation without offensive timing")
	host.free()
	c=fresh("FO")
	for id in ["FO01","FO08","FO09"]:p.learn(id)
	host=load("res://scripts/combat/battle_host.gd").new();host.combat=c;root.add_child(host);host.active=true;host.tactical.begin()
	var shortcut:=InputEventKey.new();shortcut.pressed=true;shortcut.physical_keycode=KEY_6;host._unhandled_input(shortcut)
	check(host.tactical.selected_skill==100,"Keyboard reaches the sixth firearm action, including the new manual")
	for i in 5:
		var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_Y;pad.pressed=true;host._unhandled_input(pad)
	check(host.tactical.selected_skill==100,"Controller Y cycles through all firearm techniques including the new study")
	host.free()
	var artwork=load("res://scripts/combat/portugal_actor_art.gd")
	c.mode="order_trial"
	check(artwork.identity(c,c.units[2])=="order_instructor","Orientation uses the actual Order instructor instead of Tome art")
	var entry: Dictionary=artwork.data().order_instructor
	check(entry.frames.size()==9 and entry.grips.size()==9,"Instructor combat has nine real illustrated poses and hand anchors")
	var source=Image.load_from_file(entry.source)
	for i in 9:
		var frame: Array=entry.frames[i];var grip: Array=entry.grips[i]
		check(Rect2i(Vector2i.ZERO,source.get_size()).encloses(Rect2i(frame[0],frame[1],frame[2],frame[3])),"Instructor pose within source image "+str(i))
		check(grip[0]>=0 and grip[1]>=0 and grip[0]<frame[2] and grip[1]<frame[3],"Instructor grip remains inside its original pose "+str(i))
	print("ORDER_STUDIES_RESULT ",JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
