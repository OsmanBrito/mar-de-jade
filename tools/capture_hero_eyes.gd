extends SceneTree
class Gallery:
	extends Node2D
	const Eyes = preload("res://scripts/chapter/hero_eyes.gd")
	var rows: Array = []
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,800),Color("18312f"))
		for i in rows.size():
			var row: Dictionary = rows[i]
			var point := Vector2(20+(i%8)*157,35+(i/8)*150)
			draw_string(ThemeDB.fallback_font,point,row.key+" "+str(row.index),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("eee4cb"))
			var at: Array = Eyes.ANCHORS[row.key][row.index][0]
			var crop := Rect2(at[0]-52,at[1]-32,104,78)
			draw_set_transform(point+Vector2(0,12))
			draw_texture_rect_region(row.texture,Rect2(0,0,140,105),crop)
			Eyes.draw(self,row.key,row.index,[crop.position.x,crop.position.y,104,78],[0,0],140.0/104.0,row.get("glow",false))
			draw_set_transform(Vector2.ZERO)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,800)
	var gallery := Gallery.new(); root.add_child(gallery)
	for spec in [["walk","res://assets/art/portugal-v2/hero-walk-v1.png",[0,1,4,5,12,13]],["child","res://assets/art/npcs/lisbon/hero_child-v1.png",[0,4,12,16,17,18,19]],["story","res://assets/art/portugal-v2/hero-story-poses-v1.png",[0,1,2,3]],["combat","res://assets/art/combat/portugal/hero-v1.png",[0,3,4,6]],["combat_child","res://assets/art/combat/portugal/hero_child-v1.png",[0,1,3,4,6]]]:
		for index in spec[2]: gallery.rows.append({"key":spec[0],"index":index,"texture":load(spec[1])})
	gallery.rows.append({"key":"walk","index":0,"texture":load("res://assets/art/portugal-v2/hero-walk-v1.png"),"glow":true})
	gallery.queue_redraw()
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/revision-eyes.png")
	gallery.free(); quit()
