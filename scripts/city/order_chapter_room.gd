extends Node2D
const Materials=preload("res://scripts/city/place_materials.gd")
const Furniture=preload("res://scripts/chapter/furniture_art.gd")
const Actor=preload("res://scripts/chapter/actor_proxy.gd")
const Marker=preload("res://scripts/chapter/local_request_marker.gd")
const Campaign=preload("res://scripts/chapter/order_campaign.gd")
var grandmaster
var duarte
var markers: Dictionary={}
static func install(map) -> void:
	var room:=Node2D.new();room.set_script(load("res://scripts/city/order_chapter_room.gd"));room.name="OrderChapterRoom";room.z_index=-3;map.add_child(room)
	for rect in [Rect2(80,-920,620,14),Rect2(80,-920,14,510),Rect2(686,-920,14,510)]:load("res://scripts/city/convent_scenery.gd").box(map,rect)
	Furniture.place(map.sorted_world,"table",Vector2(420,-715),Vector2(210,115))
	Furniture.place(map.sorted_world,"bench",Vector2(480,-825),Vector2(130,85))
	Furniture.place(map.sorted_world,"cupboard",Vector2(160,-810),Vector2(110,150))
	Furniture.place(map.sorted_world,"shelf",Vector2(630,-790),Vector2(100,130))
	var papers:=Node2D.new();papers.set_script(load("res://scripts/city/order_service_props.gd"));papers.kind="chapter";papers.position=Vector2(420,-715);map.sorted_world.add_child(papers)
	for id in Campaign.ROWS:
		var holder:=Node2D.new();holder.position=Campaign.ROWS[id].at;map.sorted_world.add_child(holder)
		var marker:=Marker.new();marker.caption=Campaign.ROWS[id].title;marker.symbol="!";holder.add_child(marker)
		room.markers[id]=marker
	room.grandmaster=room.person(map,"GraoMestre","order_grandmaster",Vector2(480,-610))
	room.person(map,"ComendadorDaCasa","order_brother",Vector2(175,-565))
	room.duarte=room.person(map,"DuarteNaAudiencia","duarte",Vector2(595,-550))
func person(map,label: String,id: String,at: Vector2) -> Node2D:
	var actor:=Actor.new();actor.name=label;actor.npc_id=id;actor.position=at;map.sorted_world.add_child(actor);return actor
func _process(_delta):
	var p=get_node("/root/ChapterProgress")
	grandmaster.visible=not p.completed
	duarte.visible=not p.flags.get("order_audience_done",false) and Campaign.ready(p) and not p.completed
	for id in markers:
		markers[id].available=id!="grandmaster" or not p.completed
		markers[id].highlighted=get_parent().player.position.distance_to(Campaign.ROWS[id].at)<60
		markers[id].symbol="!" if id==("commander" if p.completed else "grandmaster") and not p.flags.get("order_audience_done",false) else "i"
func _draw():
	Materials.wall(self,Vector2(80,-920),Vector2(700,-920),130)
	preload("res://scripts/city/convent_finish.gd").threshold(self,Vector2(265,-395))
	preload("res://scripts/city/convent_finish.gd").plaque(self,Vector2(353,-395),"Capítulo",70)
	draw_rect(Rect2(375,-620,210,160),Color("8c6454"));draw_rect(Rect2(383,-612,194,144),Color("c5b38b"),false,2)
	Materials.window(self,Vector2(350,-890),55,80)
	preload("res://scripts/chapter/order_house.gd").banner(self,Vector2(560,-830),Vector2.RIGHT)
