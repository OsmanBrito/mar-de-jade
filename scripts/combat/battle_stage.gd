extends RefCounted
## Keep the reference viewport's proportions and its actual pointer coordinates.
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
	var factor := minf(window_size.x/SIZE.x,window_size.y/SIZE.y)
	container.scale = Vector2.ONE*factor
	container.position = (window_size-SIZE*factor)*0.5
	var background := container.get_parent().get_node_or_null("BattleBackdrop") as ColorRect
	if background: background.size = window_size
	var curtain := container.get_parent().get_node_or_null("BattleCurtain") as ColorRect
	if curtain: curtain.size = window_size
