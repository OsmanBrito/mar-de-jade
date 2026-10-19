@tool
extends RefCounted
## GPU-only costume treatment: source atlases, silhouettes and animation stay intact.
static var ready_textures: Dictionary = {}
static var pending: Dictionary = {}
const WALK_CHESTS := [Vector2(75,99),Vector2(77,99),Vector2(80,100),Vector2(77,100),Vector2(32,98),Vector2(53,97),Vector2(59,97),Vector2(60,97),Vector2(73,92),Vector2(72,92),Vector2(80,92),Vector2(76,92),Vector2(76,91),Vector2(98,92),Vector2(111,91),Vector2(114,91),Vector2(73,67),Vector2(64,70),Vector2(76,65),Vector2(82,72)]
const BATTLE_CHESTS := [Vector2(149,132),Vector2(157,132),Vector2(166,129),Vector2(161,119),Vector2(177,119),Vector2(160,121),Vector2(154,118),Vector2(148,111),Vector2(153,91)]

static func texture(canvas: CanvasItem,source: Texture2D,entry: Dictionary,battle: bool = false) -> Texture2D:
	var key := "battle" if battle else "walk"
	if ready_textures.has(key): return ready_textures[key]
	if DisplayServer.get_name()=="headless" or not canvas.is_inside_tree(): return source
	if not pending.has(key):
		pending[key] = true
		bake.call_deferred(canvas,source,entry,battle,key)
	return source

static func bake(canvas: CanvasItem,source: Texture2D,entry: Dictionary,battle: bool,key: String) -> void:
	if not is_instance_valid(canvas) or not canvas.is_inside_tree(): pending.erase(key); return
	var viewport := SubViewport.new(); viewport.name = "OrderLivery_"+key
	viewport.size = Vector2i(source.get_size()); viewport.transparent_bg = true; viewport.disable_3d = true; viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var sprite := Sprite2D.new(); sprite.texture = source; sprite.centered = false
	var material := ShaderMaterial.new(); material.shader = preload("res://assets/shaders/order_livery.gdshader")
	var regions := PackedVector4Array(); var marks := PackedVector4Array()
	for i in entry.frames.size():
		var r: Array = entry.frames[i]
		var chest: Vector2 = (BATTLE_CHESTS if battle else WALK_CHESTS)[i]
		var side: bool = not battle and (i in range(4,8) or i in range(12,16) or i>=18)
		var top: float = float(r[3])*(.21 if battle else .20)
		var bottom: float = float(r[3])*(.56 if battle else .55)
		# Follow the full cloth silhouette rather than laying a rectangular bib on it.
		var width: float = 24.0 if side else 65.0 if battle else 40.0
		regions.append(Vector4(float(r[0])+chest.x-width,float(r[1])+top,width*2,bottom-top))
		marks.append(Vector4(float(r[0])+chest.x,float(r[1])+chest.y,7 if side else 13 if battle else 11,18 if battle else 14))
	material.set_shader_parameter("atlas_size",source.get_size()); material.set_shader_parameter("region_count",entry.frames.size())
	material.set_shader_parameter("torso_regions",regions); material.set_shader_parameter("insignia_regions",marks)
	sprite.material = material; viewport.add_child(sprite); canvas.get_tree().root.add_child(viewport)
	await RenderingServer.frame_post_draw
	if not is_instance_valid(viewport): pending.erase(key); return
	var rendered := viewport.get_texture().get_image()
	rendered.fix_alpha_edges(); rendered.generate_mipmaps()
	var filtered := CanvasTexture.new(); filtered.diffuse_texture = ImageTexture.create_from_image(rendered)
	filtered.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ready_textures[key] = filtered; pending.erase(key); viewport.queue_free()
