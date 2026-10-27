extends SceneTree
const Social = preload("res://scripts/city/city_conversations.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	var p = root.get_node("ChapterProgress")
	p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Miguel"
	var requests: Dictionary = p.local_requests.duplicate()
	var coins: int = p.coins
	for id in Social.TITLES:
		check(not Social.introduction(p,id).is_empty() and Social.introduction(p,id).is_empty(),"Resident greets once: "+id)
		check(Social.consequence(p,id).is_empty(),"Unfinished local work is not remembered as completed: "+id)
		var first: String = Social.take_reply(p,id)
		check(not first.is_empty() and first!=Social.take_reply(p,id),"Resident has two distinct ordinary subjects: "+id)
	p.flags.recovered = true; p.flags.city_leonor_demonstrated = true
	check(Social.event(p)=="recovery","Recovery gets a current response instead of yesterday's demonstration")
	for id in Social.TITLES:
		check(Social.take_reply(p,id)==Social.REACTIONS.recovery[id],"Resident acknowledges recovery without disclosing the private duel: "+id)
	p.flags.packed = true
	check(Social.event(p)=="departure","Departure takes precedence over recovery")
	p.journey = {"kind":"port_visit"}
	check(Social.event(p)=="return","A shore visit takes precedence over previous story flags")
	check(Social.reply(p,"workshop",0).find("carro já está ao serviço")==-1,"Return does not imply that the optional cart was repaired")
	check(p.local_requests==requests and p.coins==coins,"Conversation alone never starts a request or grants payment")
	p.local_requests = {"C01-LIS-01":"completed","C01-LIS-02":"completed","C01-LIS-03":"completed","C01-LIS-04":"completed"}
	for id in Social.TITLES:
		var remembered: String = Social.consequence(p,id)
		check(not remembered.is_empty() and Social.reply(p,id,1)==remembered,"Completed work becomes a specific shared memory: "+id)
		check(Social.reply(p,id,2)!=Social.reply(p,id,3),"Ordinary subjects remain available after the event and memory: "+id)
		check(Social.take_reply(p,id)==Social.REACTIONS["return"][id] and Social.take_reply(p,id)==remembered,"Actual topic cursor shows the event before the shared memory: "+id)
		var work: String = Social.take_reply(p,id)
		check(work!=Social.take_reply(p,id) and Social.take_reply(p,id)==work,"Actual topic cursor alternates work after the one-time memory: "+id)
	var topics: Dictionary = {}
	for id in Social.TITLES:
		for context in ["","accident","rescue","demonstration","recovery","departure","return"]: topics[id+":"+context] = 3
	check(Social.valid_topics(topics) and topics.size()==35,"Every valid resident context fits the additive save field")
	var invalid: Dictionary = topics.duplicate(); invalid.erase("fisher:return"); invalid["fisher:private_duel"] = 1
	check(not Social.valid_topics(invalid),"Unknown context is still rejected")
	p.reset(); p.city_topics = topics
	var saved: Dictionary = p.snapshot()
	check(p.restore(saved)==OK and p.city_topics==topics,"All conversation contexts round-trip through campaign validation")
	print("LISBON_DIALOGUE_FINISH_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
