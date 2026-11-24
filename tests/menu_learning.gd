extends SceneTree
const Order=preload("res://scripts/chapter/order_campaign.gd")
const Dev=preload("res://scripts/chapter/character_development.gd")
var checks:=0
var failures: Array[String]=[]
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message); push_error(message)
func run():
	var p=root.get_node("ChapterProgress"); p.auto_save=false; p.reset()
	p.flags.recovered=true; p.learn("ES07")
	var before: Dictionary=p.snapshot()
	Order.study(p,"ES09")
	check(p.snapshot()==before,"Missing manual cannot learn or change state")
	p.flags.order_audience_done=true; p.flags.order_manual_ES09=true
	check(not Order.study_reason(p,"ES09").is_empty(),"Evaluation requirement remains visible")
	p.flags.order_trial_done=true
	check(Order.study_reason(p,"ES09").is_empty(),"Owned authorized manual can be studied")
	var slots: Array=Dev.member(p).active_skills.duplicate()
	var coins: int=p.coins; var vitals: Dictionary=p.vitals.duplicate()
	Order.study(p,"ES09")
	check(p.skills.has("ES09") and Dev.member(p).active_skills==slots,"Learning preserves chosen loadout")
	check(p.coins==coins and p.vitals==vitals,"Studying charges no second payment and grants no healing")
	Dev.toggle_skill(p,"ES09")
	check(Dev.equipped(p,"ES09"),"Learned study can be prepared directly")
	before=p.snapshot(); Order.study(p,"ES09")
	check(p.snapshot()==before,"Learning twice is idempotent")
	Dev.toggle_skill(p,"ES09")
	check(not Dev.equipped(p,"ES09") and p.skills.has("ES09"),"Removing preparation preserves knowledge")
	p.reset(); p.auto_save=false; p.flags.recovered=true; p.flags.order_audience_done=true; p.learn("ES07"); p.coins=60
	before=p.snapshot(); Order.acquire(p,"ES09",false)
	check(p.snapshot()==before,"Combined purchase rejects unmet evaluation without charging")
	p.flags.order_trial_done=true; slots=Dev.member(p).active_skills.duplicate()
	Order.acquire(p,"ES09",false)
	check(p.coins==30 and p.skills.has("ES09") and Order.purchased(p,"ES09"),"Gold purchase learns executable technique in one transaction")
	check(Dev.member(p).active_skills==slots,"Buying keeps chosen active slots")
	before=p.snapshot(); Order.acquire(p,"ES09",false)
	check(p.snapshot()==before,"Repeated purchase cannot charge twice")
	p.learn("LA07"); Order.acquire(p,"LA09",true)
	check(p.coins==30 and p.skills.has("LA09") and p.flags.order_voucher_used,"Voucher learns without spending gold")
	p.learn("PU07"); before=p.snapshot(); Order.acquire(p,"PU09",true)
	check(p.snapshot()==before,"Spent voucher cannot acquire another technique")
	check(["duty","power","cargo","training"].all(func(id):return Order.LEADER_TOPICS.has(id)) and Order.leader_topics().size()==Order.LEADER_TOPICS.size(),"Leader offers personal conversation topics and practical training guidance")
	for key in Order.LEADER_TOPICS:
		check(Order.LEADER_TOPICS[key].text.begins_with("Grão-Mestre —") and Order.LEADER_TOPICS[key].text.length()>160,"Leader topic has authored dialogue: "+key)
	print("MENU_LEARNING_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
