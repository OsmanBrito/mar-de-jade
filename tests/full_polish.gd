extends SceneTree
const Social=preload("res://scripts/city/city_conversations.gd")
const Life=preload("res://scripts/city/city_life.gd")
const Results=preload("res://scripts/city/work_results.gd")
const Summary=preload("res://scripts/chapter/save_summary.gd")
const Bridge=preload("res://scripts/navigation/shore_bridge.gd")
const Kit=preload("res://scripts/navigation/boarding_loadout.gd")
const Items=preload("res://scripts/chapter/player_items.gd")
const Portraits=preload("res://scripts/chapter/dialogue_portraits.gd")
const Animals=preload("res://scripts/city/forest_animal.gd")
const Bond=preload("res://scripts/chapter/childhood_bond.gd")
var checks:=0
var failures: Array[String]=[]
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures.append(message);push_error(message)
func frames(n:int=5):
 for i in n:await process_frame
func run():
 var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
 root.get_node("CampaignProfile").hero_name="Miguel"
 p.flags.patient_helped=true
 var first:String=Social.take_reply(p,"workshop")
 var second:String=Social.take_reply(p,"workshop")
 check(first!=second and first.contains("carga"),"The event reaction is followed by a different work subject")
 check(p.save_to("user://polish-social.json")==OK,"Social state uses the actual save writer")
 var stored:Dictionary=p.snapshot()
 var third:String=Social.take_reply(p,"workshop")
 p.reset()
 check(p.load_from("user://polish-social.json")==OK and Social.take_reply(p,"workshop")==third,"Disk reload continues the next subject instead of repeating the reaction")
 check(Social.take_reply(p,"workshop")==second,"Work subjects alternate after the one-time reaction")
 p.flags.packed=true
 check(Social.take_reply(p,"workshop").contains("Madeira"),"A new story context has its own initial reaction")
 var stable:Dictionary=p.snapshot()
 for bad in [null,[],{"ghost:return":1},{"workshop:wrong":1},{"workshop:return":1.2},{"workshop:return":4},{"workshop:return":-1}]:
  var invalid:Dictionary=stable.duplicate(true);invalid.city_topics=bad
  check(p.restore(invalid)==ERR_INVALID_DATA and p.snapshot()==stable,"Invalid social state rejects atomically: "+str(bad))
 var missing:Dictionary=stable.duplicate(true);missing.erase("city_topics")
 check(p.restore(missing)==ERR_INVALID_DATA,"Version 12 requires social state")
 missing.schema_version=11
 check(p.restore(missing)==OK and p.city_topics.is_empty() and p.run_id==stable.run_id,"Version 11 migrates without inventing conversations or identities")
 p.restore(stored)
 p.coins=37;check(p.save_to("user://polish-summary.json")==OK,"Summary checkpoint saves")
 p.coins=2
 var summary:String=Summary.chapter(p,"user://polish-summary.json")
 check(summary.contains("37 de ouro") and not summary.contains("2 de ouro"),"Load preview reads saved resources instead of live resources")
 var cycles:Dictionary={}
 for id in Life.CYCLES:
  var phases:Dictionary={}
  var bounded:=true
  for i in 300:
   var step:Dictionary=Life.routine(id,i*.1)
   phases[step.phase]=true
   bounded=bounded and step.weight>=0 and step.weight<=1
  check(bounded,"Routine progress stays bounded: "+id)
  check(phases.size()==5,"Every work routine reaches all five phases: "+id)
  cycles[Life.routine(id,0).cycle]=true
 check(cycles.size()==5,"Residents have distinct routine lengths")
 for id in ["wolf","bear","deer"]:
  for pose in ["ready","attack","kneel"]:
   check(Animals.walk_blend(id,pose,.17).weight==0,"Non-walking combat poses never blend early: "+id+pose)
  for time in [.0,.13,.15,.17,.19,.35]:
   var blend:Dictionary=Animals.walk_blend(id,"walk",time)
   check(blend.weight>=0 and blend.weight<=1,"Walking crossfade stays bounded")
 check(not Bond.environment_hint(1,Vector2(600,1050)).is_empty(),"A nearby footprint is readable")
 check(Bond.environment_hint(1,Vector2(-1000,-1000)).is_empty() and Bond.environment_hint(0,Vector2(600,1050)).is_empty(),"Clue text respects distance and progress")
 var metadata:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/portraits/cast-busts-v2.json"))
 for id in metadata.entries:
  var texture:AtlasTexture=Portraits.portrait(id)
  check(texture!=null and absf(texture.region.size.x/texture.region.size.y-5.0/6)<.001,"Cast framing follows the common bust ratio: "+id)
  check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region),"Bust crop stays inside its source: "+id)
 var music:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/chapter/music/playlist.json"))
 for row in music.tracks.values():
  check(absf(row.input_lufs+row.gain_db+22)<.011 and row.input_true_peak_db+row.gain_db<=-2,"Music gain meets the measured loudness and peak limits")
 p.reset();p.completed=true;p.checkpoint=16;p.entry_scene="res://scenes/chapter_01/chapter_flow.tscn"
 p.flags={"recovered":true,"embarked":true,"packed":true,"patient_helped":true,"patient_stable":true,"perfect_defense":true}
 p.coins=40;p.vitals={"hp":80,"qi":5,"posture":65};p.companion_vitals={"duarte":{"hp":70,"qi":3,"posture":50}}
 var ship=load("res://scripts/navigation/voyage_model.gd").new()
 ship.hero_name="Miguel";ship.campaign_state=p.snapshot();ship.boarding_profile=Kit.capture(ship.campaign_state);ship.dock("lisboa")
 ship.coins=211;ship.hull=73;ship.supplies=62
 var path:="user://polish-cycles.json"
 for cycle in 5:
  check(Bridge.enter(ship,path)==OK,"Shore visit starts: "+str(cycle))
  var money:int=p.coins
  Items.buy(p,"PT-C03")
  Social.take_reply(p,"dock")
  check(p.coins==money-3 and p.save_to()==OK,"Shore purchase persists without duplicate funds")
  check(Summary.chapter(p).contains("visita e o navio"),"Shore load preview consults the authoritative parked voyage")
  check(Bridge.embark(p)==OK and ship.load_from(path)==OK,"Reboarding resumes the same parked file")
  check(ship.coins==211 and ship.hull==73 and ship.supplies==62 and ship.campaign_state.coins==40-(cycle+1)*3,"Repeated shore cycles preserve separate economies and ship resources")
  check(int(ship.campaign_state.city_topics["dock:return"])==p.city_topics["dock:return"] and ship.campaign_state.companion_vitals.duarte.hp==70,"Social topics and companion identity survive every cycle")
 var profile:Dictionary=Kit.capture(p.snapshot())
 profile.vitals={"hp":20,"qi":0,"posture":5}
 var ready:String=Kit.readiness(profile)
 check(ready.contains("ferido") and ready.contains("Pouco alento") and ready.contains("Postura baixa") and ready.contains("5 água"),"Preparation summary exposes actual wounds, low resources and personal supplies")
 p.journey={"kind":"port_visit","target":16,"event":-1,"stage":"","area":"cais","position":[1496,1105]}
 var world=load("res://scenes/chapter_01/chapter_flow.tscn")
 if world==null:
  check(false,"City map loads")
 else:
  var scene=world.instantiate();root.add_child(scene);await frames()
  var map=scene.world
  check(map.sorted_world.get_node("Vizinha").npc_id=="dock_woman" and Portraits.identity("Vizinha",false,"Miguel")=="dock_woman","The kitchen neighbor has the same female identity in map and dialogue")
  var route_rows:Array=[]
  for leg in [["portaria_ribeira",Vector2(-690,145),Vector2(1496,1105)],["poente_batel",Vector2(-900,430),Vector2(-485,1185)],["nascente_armazem",Vector2(735,360),Vector2(1645,650)],["mercado_cozinha",Vector2(650,1030),Vector2(315,955)]]:
   var route:PackedVector2Array=map.navigation.get_point_path(map._nearest_id(leg[1]),map._nearest_id(leg[2]))
   check(route.size()>1,"The repeated route has a complete navigation path: "+leg[0])
   var length:=0.0
   for i in range(1,route.size()):length+=route[i-1].distance_to(route[i])
   route_rows.append({"route":leg[0],"path_pixels":roundi(length),"walk_seconds_no_stops":snappedf(length/140,.1)})
  print("ROUTE_AUDIT ",JSON.stringify(route_rows))
  DirAccess.make_dir_recursive_absolute("res://.qa-runtime/full-polish")
  var audit=FileAccess.open("res://.qa-runtime/full-polish/routes.json",FileAccess.WRITE)
  audit.store_string(JSON.stringify(route_rows,"  "));audit.close()
  var total:int=p.coins
  Results.apply(map,p)
  for id in ["C01-LIS-01","C01-LIS-02","C01-LIS-03","C01-LIS-04"]:p.local_requests[id]="completed"
  Results.apply(map,p)
  var count:=0
  for node in map.sorted_world.find_children("WorkResult","Node2D",true,false):
   if node.visible:count+=1
  check(count==4 and p.coins==total,"All completed requests produce physical results without granting rewards again")
  if DisplayServer.get_name()!="headless":
   DirAccess.make_dir_recursive_absolute("res://.qa-runtime/full-polish/captures")
   for anchor_name in ["CarroDaOficina","BancaDePeixe","TrabalhadorDoPontao","AmarraDoBatel"]:
    var anchor=map.sorted_world.get_node(anchor_name)
    map.player.position=anchor.position+Vector2(60,50)
    await frames(12);await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://.qa-runtime/full-polish/captures/"+anchor_name+".png")
  Results.apply(map,p)
  check(map.sorted_world.find_children("WorkResult","Node2D",true,false).size()==4,"Reloading results never duplicates their scene nodes")
  if DisplayServer.get_name()!="headless":
   for at in [Vector2(-900,600),Vector2(1660,700)]:
    map.player.position=at;map.player.camera.reset_smoothing()
    await frames(16);await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://.qa-runtime/full-polish/captures/street-"+str(int(at.x))+".png")
  scene.free()
 p.reset();check(p.city_topics.is_empty(),"A new campaign clears old social topics")
 print("FULL_POLISH_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
