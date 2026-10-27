extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,text:String) -> void:
	checks+=1
	if not ok:failures.append(text);push_error(text)
func frames(n:int=12) -> void:
	for i in n:await process_frame
func run() -> void:
	var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();root.get_node("CampaignProfile").hero_name="Miguel"
	var game=load("res://scenes/chapter_01/childhood_home.tscn").instantiate();root.add_child(game);current_scene=game;await frames()
	check(root.has_node("ChildhoodPacing"),"Explicit launch flag installs one local timer")
	var timer=root.get_node("ChildhoodPacing")
	check(timer.report().total_seconds>0 and timer.report().by_scene_seconds.has("opening.tscn"),"Actual shelter frames are counted")
	var diary_before:float=timer.report().total_seconds
	game.get_node("ChildhoodMenu").open("journal");await frames(20)
	check(timer.report().total_seconds>diary_before,"Natural diary reading is counted even though world simulation pauses")
	game.get_node("ChildhoodMenu").open("history");await frames(2)
	var history_before:float=timer.report().total_seconds
	await frames(20)
	check(timer.report().total_seconds>history_before,"Reading past conversations counts as natural reading")
	game.get_node("ChildhoodMenu").close()
	paused=true
	var before:float=timer.report().total_seconds
	await frames(20)
	check(timer.report().total_seconds==before,"Actual paused frames are excluded")
	paused=false;game.free();await frames(2)
	var adult=load("res://scenes/chapter_01/adult_opening.tscn").instantiate();root.add_child(adult);current_scene=adult;await frames()
	check(timer.finished and FileAccess.file_exists("user://childhood-pacing.json"),"Real adult handoff closes and writes the report")
	var report:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://childhood-pacing.json"))
	check(report.reached_adulthood and not report.complete_childhood and not report.by_scene_seconds.has("adult_opening.tscn"),"Partial saved report excludes adulthood and does not claim full coverage")
	check(not JSON.stringify(report).contains("Miguel") and not report.human_reading_validated,"Local log contains no character name or false human approval")
	adult.free();await frames(2)
	print("CHILDHOOD_TIMING_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
