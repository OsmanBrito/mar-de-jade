extends RefCounted
## Render one combat texel per window pixel, independently of the campaign stretch.
const SIZE := Vector2(960,540)
static func install(layer: CanvasLayer,container: SubViewportContainer) -> void:
	var background := ColorRect.new(); background.name = "BattleBackdrop"; background.color = Color("102c37"); background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(background); layer.move_child(background,0)
	container.visibility_changed.connect(func(): background.visible = container.visible)
	var curtain := preload("res://scripts/combat/battle_curtain.gd").new()
	curtain.name = "BattleCurtain"; curtain.color = Color("102c37"); curtain.mouse_filter = Control.MOUSE_FILTER_STOP; curtain.hide()
	layer.add_child(curtain)
static func curtain_for(host: Node) -> ColorRect:
	var viewport := host.get_viewport()
	if viewport==null: return null
	var container := viewport.get_parent()
	return container.get_parent().get_node_or_null("BattleCurtain") as ColorRect if container!=null and container.get_parent()!=null else null
static func cover(host: Node,opacity: float) -> void:
	var curtain := curtain_for(host)
	if curtain==null: return
	curtain.modulate.a = clampf(opacity,0,1); curtain.visible = opacity>0
static func fit(container: SubViewportContainer,window_size: Vector2) -> void:
	# window_size is in the campaign's logical coordinates (1440x900), not pixels.
	# A SubViewport does not inherit canvas_items' native-resolution rendering.
	# Cancel the outer stretch on its container and allocate the actual pixel area.
	var outer := container.get_viewport().get_final_transform()
	var pixel_scale := Vector2(outer.x.length(),outer.y.length())
	var pixels := Vector2i((window_size*pixel_scale).round()).max(Vector2i(2,2))
	var factor := minf(float(pixels.x)/SIZE.x,float(pixels.y)/SIZE.y)
	container.scale = Vector2.ONE/pixel_scale
	container.position = Vector2.ZERO
	container.size = Vector2(pixels)
	# The viewport texture is presented 1:1; its illustrated assets filter inside it.
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var viewport := container.get_child(0) as SubViewport if container.get_child_count()>0 else null
	if viewport:
		if not container.stretch: viewport.size = pixels
		viewport.canvas_transform = Transform2D(Vector2(factor,0),Vector2(0,factor),(Vector2(pixels)-SIZE*factor)*0.5)
		# An explicit canvas_transform does not update automatic font oversampling.
		viewport.oversampling_override = maxf(1.0,factor)
	var background := container.get_parent().get_node_or_null("BattleBackdrop") as ColorRect
	if background: background.size = window_size
	var curtain := container.get_parent().get_node_or_null("BattleCurtain") as ColorRect
	if curtain: curtain.size = window_size

static func ui_to_window(host: Node,point: Vector2) -> Vector2:
	var viewport := host.get_viewport()
	var container := viewport.get_parent() as SubViewportContainer
	return container.get_global_transform()*viewport.canvas_transform*point if container else point
