extends Node
## Opt-in local wall-clock report; no telemetry, network or player-identifying fields.
const PATH:="user://childhood-pacing.json"
const SCENES:=["opening.tscn","plaza.tscn","training.tscn","forest_hunt.tscn","promise.tscn"]
var seconds:Dictionary={}
var last_tick:=0
var elapsed_write:=0.0
var finished:=false
var run_id:=""
static func install(host:Node) -> void:
	if not OS.get_cmdline_user_args().has("--measure-childhood"):return
	if host.get_tree().root.has_node("ChildhoodPacing"):return
	var timer:=Node.new();timer.set_script(load("res://scripts/chapter/childhood_pacing.gd"));timer.name="ChildhoodPacing";host.get_tree().root.add_child.call_deferred(timer)
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;last_tick=Time.get_ticks_msec()
func sample(scene:String,wall_seconds:float,is_paused:bool) -> void:
	if finished or is_paused:return
	if scene=="childhood_home.tscn":scene="opening.tscn"
	if not SCENES.has(scene):
		if not seconds.is_empty() and scene in ["adult_opening.tscn","chapter_flow.tscn"]:finished=true
		return
	seconds[scene]=float(seconds.get(scene,0.0))+maxf(0,wall_seconds)
func report() -> Dictionary:
	var total:=0.0
	for value in seconds.values():total+=float(value)
	return {"measurement":"local_wall_clock_excluding_pause_including_journal","complete_childhood":finished and SCENES.all(func(scene):return seconds.has(scene)),"reached_adulthood":finished,"missing_scenes":SCENES.filter(func(scene):return not seconds.has(scene)),"total_seconds":snappedf(total,.01),"by_scene_seconds":seconds.duplicate(),"target_seconds":[1800,2700],"human_reading_validated":false}
func flush() -> void:
	var file:=FileAccess.open(PATH,FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(report(),"  "))
func _process(_delta:float) -> void:
	var now:=Time.get_ticks_msec();var elapsed:=float(now-last_tick)/1000.0;last_tick=now
	var p=get_node_or_null("/root/ChapterProgress")
	if p==null:return
	if run_id!=p.run_id:
		seconds.clear();finished=false;run_id=p.run_id
	var before:=finished
	if before:return
	var counting_pause:bool=get_tree().paused
	var scene=get_tree().current_scene
	var menu=scene.get_node_or_null("ChildhoodMenu") if is_instance_valid(scene) else null
	if menu!=null and menu.opened and menu.page in ["journal","history"] and not menu.settings_open:counting_pause=false
	sample(str(p.entry_scene).get_file(),elapsed,counting_pause)
	elapsed_write+=elapsed
	if (finished and not before) or elapsed_write>=10:
		elapsed_write=0;flush()
func _exit_tree() -> void:flush()
