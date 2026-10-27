extends SceneTree
const Book=preload("res://scripts/chapter/order_techniques.gd")
const Order=preload("res://scripts/chapter/order_campaign.gd")
const Dev=preload("res://scripts/chapter/character_development.gd")
var Rules
var p
var checks:=0
var failures: Array[String]=[]
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message); push_error(message)
func fixture(id: String,grade: int):
	p.reset(); p.auto_save=false; p.flags.recovered=true; p.flags.order_audience_done=true; p.flags.order_trial_done=true
	p.style=Book.rows()[id].style; p.learn(Book.FIRST[p.style]); p.learn(id)
	var record: Dictionary=Dev.member(p); record.active_skills=[id]; record.practice[id]=[0,8,20][grade-1]
	var c=Rules.new(); c.start_encounter("practice","Miguel",p.style); c.obstacles.clear()
	if id=="FO57": c.low_cover.assign([Vector2i(7,3),Vector2i(6,4)])
	c.current_id=0; c.units[0].cell=Vector2i(4,3); c.units[0].turn_origin=c.units[0].cell; c.units[0].qi=100; c.units[0].max_qi=100; c.units[0].moves=5; c.units[0].acted=false; c.units[0].face=0
	c.units[1].hp=100; c.units[1].max_hp=100; c.units[1].withdrawn=false; c.units[1].team=0; c.units[1].cell=Vector2i(4,4)
	c.units[2].cell=Vector2i(5,3); c.units[2].kind="defender"; c.units[2].guard=false; c.units[2].face=2
	for i in range(3,c.units.size()): c.units[i].hp=0
	return c
func run():
	Rules=load("res://scripts/combat/campaign_rules.gd"); p=root.get_node("ChapterProgress"); p.auto_save=false
	check(Book.rows().size()==65,"Complete catalogue has 65 Medida techniques")
	for style in ["ES","LA","MC","FO","PU"]: check(Book.rows().values().filter(func(r): return r.style==style).size()==13,style+" has thirteen techniques")
	for id in Book.rows():
		if Book.LEGACY.has(id): continue
		for grade in [1,2,3]:
			var c=fixture(id,grade); var action: int=Book.action(id); var d: Dictionary=c.skill_def(0,action)
			check(c.commands(0).has(action),id+" prepared command exposed")
			check(d.content_id==id and d.level==grade,id+" grade "+str(grade)+" preserves unique ID")
			var aim: Vector2i=c.units[0].cell if d.shape=="self" else c.units[1].cell if d.shape=="ally" else c.units[2].cell
			if id in ["LA12","LA15"]: c.units[2].cell=Vector2i(6,3); aim=c.units[2].cell
			var before: Dictionary=p.snapshot(); var qi: int=c.units[0].qi
			check(c.attack_reason(action,aim).is_empty(),id+" legal geometry accepted")
			var predicted: Dictionary={} if d.shape in ["self","ally"] else c.predict(0,2,action,1,aim)
			var hp: int=c.units[2].hp
			var result: Dictionary=c.perform(action,aim,1)
			check(not result.has("error"),id+" executes at grade "+str(grade))
			check(c.units[0].qi==qi-int(d.cost) and c.units[0].acted,id+" pays declared alento and one action")
			check(p.snapshot()==before,id+" combat does not mutate campaign resources")
			if not predicted.is_empty(): check(hp-c.units[2].hp==predicted.damage,id+" prediction equals impact")
			var state: Dictionary=c.units[0].duplicate(true); result=c.perform(action,aim,1)
			check(result.has("error") and c.units[0]==state,id+" cannot execute a second main action")
		var c=fixture(id,1); var action: int=Book.action(id); c.units[0].qi=0
		var stable: Dictionary=c.units[0].duplicate(true); var result: Dictionary=c.perform(action,c.units[2].cell,1)
		check(result.has("error") and c.units[0]==stable,id+" insufficient alento rejects atomically")
	# Requirements are independent from wealth and buying never grants cultivation.
	fixture("ES10",1); p.skills.erase("ES10"); p.coins=10000
	check(not Order.acquire_reason(p,"ES10",false).is_empty(),"Wealth cannot bypass Circulação")
	Dev.member(p).cultivation.rank=1; Dev.member(p).proficiency.ES=100
	check(not Order.acquire_reason(p,"ES10",false).is_empty(),"Cultivation cannot bypass campaign teaching")
	p.development.claimed.append("C03-M02")
	check(Order.acquire_reason(p,"ES10",false).is_empty(),"Correct rank proficiency and milestone unlock study")
	var gold: int=p.coins; Order.acquire(p,"ES10",false)
	check(p.skills.has("ES10") and p.coins==gold-Book.price("ES10"),"Advanced price charged exactly once")
	print("MEDIDA_CATALOGUE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
