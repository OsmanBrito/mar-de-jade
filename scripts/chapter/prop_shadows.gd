extends Node2D
## Ground shadows for every free-standing painted object in an outdoor map: a soft
## contact pool at the base plus the object's own silhouette laid on the ground,
## falling the same way as the characters' shadows (light from the upper left).
## The prop node's position is its ground contact; all its Sprite2D strips are used.
const Shadows = preload("res://scripts/chapter/contact_shadow.gd")
## Buildings, the ship and roof scenery are skipped (they sit on their own footprints).
const SKIP_PREFIXES := ["Abrigo","Armazem","Oficina","Casa","Telhados","Caravela","Cidade"]
var props: Array[Node2D] = []
var collected := false

static func install(world: Node2D) -> void:
	if world.has_node("SombrasDosObjetos"): return
	var shadows := Node2D.new(); shadows.set_script(load("res://scripts/chapter/prop_shadows.gd"))
	shadows.name = "SombrasDosObjetos"; shadows.z_index = 1
	world.add_child(shadows)

func _process(_delta: float) -> void:
	# Story props and actors are added after the map; collect once they exist.
	if collected: return
	collected = true
	var sorted: Node = get_parent().get_node_or_null("ActorsAndProps")
	if sorted == null: return
	for prop in sorted.get_children():
		if _casts(prop): props.append(prop)
	queue_redraw()
	set_process(false)

func _casts(node: Node) -> bool:
	if not node is Node2D or not node.visible or node.has_meta("no_cast_shadow"): return false
	if node is CharacterBody2D or node.get("identity") != null or node.get("npc_id") != null: return false
	if node.get("sloped_depth") == true: return false
	for prefix in SKIP_PREFIXES:
		if String(node.name).begins_with(prefix): return false
	return not _sprites(node).is_empty()

func _sprites(node: Node) -> Array[Sprite2D]:
	var found: Array[Sprite2D] = []
	for child in node.get_children():
		if child is Sprite2D and child.visible and child.texture != null: found.append(child)
		elif child is Node2D and not child is CollisionObject2D: found.append_array(_sprites(child))
	return found

func _draw() -> void:
	for prop in props:
		if not is_instance_valid(prop) or not prop.visible: continue
		var foot := prop.position
		var sprites := _sprites(prop)
		var bounds := Rect2()
		for sprite in sprites:
			var local := prop.transform*sprite.transform
			var rect := sprite.get_rect()
			var corners := [local*rect.position,local*rect.end]
			bounds = Rect2(corners[0],Vector2.ZERO).expand(corners[1]) if bounds.size == Vector2.ZERO else bounds.expand(corners[0]).expand(corners[1])
		var width := absf(bounds.size.x)
		Shadows.draw_contact(self,foot,Vector2(width*0.42,width*0.14))
		# Shear about the ground contact: x' = x - k*y, y' = -0.3k*y (y negative is up).
		var to_ground := Shadows.cast_transform(foot,false,0.85)*Transform2D(0,-foot)
		for sprite in sprites:
			var local: Transform2D = prop.transform*sprite.transform
			if sprite.flip_h: local = local*Transform2D(Vector2(-1,0),Vector2(0,1),Vector2(sprite.get_rect().get_center().x*2.0,0))
			draw_set_transform_matrix(to_ground*local)
			draw_texture_rect(sprite.texture,sprite.get_rect(),false,Shadows.SHADOW_COLOR)
		draw_set_transform(Vector2.ZERO)
