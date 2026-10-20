extends Node2D
## Standalone playable review of the campaign host; never writes chapter saves.
const MODES := ["child_attack","child_defense","adult_basic","adult_defense","duel","school","perfect_defense","duarte_support","practice"]
const TITLES := ["Infância · básico","Infância · defesa simples","Duarte · repetição","Duarte · defesa simples","Leonor · duelo","Tomé · manejo","Tomé · Defesa Perfeita","Duarte · proteção","Prática livre · técnicas"]
@export_enum("child_attack","child_defense","adult_basic","adult_defense","duel","school","perfect_defense","duarte_support","practice") var encounter := "child_attack"
@export_enum("ES","LA","MC","FO","PU") var style := "ES"
var host
var container: SubViewportContainer
var hints: Label
var menu: PopupMenu
@export_enum("auto","plaza_child","plaza","courtyard","cais","service","room","deck") var battle_map := "auto"
func _ready() -> void:
	var bindings = preload("res://scripts/main.gd").new(); bindings.configure_input(); bindings.free()
	var layer := CanvasLayer.new(); layer.layer = 7; add_child(layer)
	container = SubViewportContainer.new(); container.size = Vector2(960,540); container.stretch = true; layer.add_child(container)
	preload("res://scripts/combat/battle_stage.gd").install(layer,container)
	var viewport := SubViewport.new(); viewport.size = Vector2i(960,540); viewport.world_2d = World2D.new(); container.add_child(viewport)
	host = preload("res://scripts/combat/battle_host.gd").new(); viewport.add_child(host)
	host.lesson_completed.connect(func(_success): hints.text = "Exercício terminado · R para repetir · F1 para escolher encontro")
	var ui := CanvasLayer.new(); ui.layer = 8; add_child(ui)
	hints = Label.new(); hints.position = Vector2(25,10); hints.add_theme_font_size_override("font_size",13); ui.add_child(hints)
	menu = PopupMenu.new(); ui.add_child(menu)
	for title in TITLES: menu.add_item(title)
	menu.id_pressed.connect(func(index):
		if index>=0 and index<MODES.size(): encounter = MODES[index]; restart())
	menu.add_separator()
	var styles := PopupMenu.new(); styles.name = "Manejos"; menu.add_child(styles)
	var style_keys := ["ES","LA","MC","FO","PU"]
	for key in style_keys: styles.add_item(preload("res://scripts/combat/campaign_rules.gd").STYLES[key].name)
	styles.id_pressed.connect(func(index): style = style_keys[index]; restart())
	menu.add_submenu_item("Manejo","Manejos")
	var maps := PopupMenu.new(); maps.name = "Mapas"; menu.add_child(maps)
	var map_ids: Array = preload("res://scripts/combat/battle_maps.gd").data().keys()
	for id in map_ids: maps.add_item(preload("res://scripts/combat/battle_maps.gd").profile(id).title)
	maps.id_pressed.connect(func(index): battle_map = map_ids[index]; restart())
	menu.add_submenu_item("Mapa de combate","Mapas")
	menu.popup_hide.connect(func(): host.paused = false)
	get_viewport().size_changed.connect(resize_stage); resize_stage(); restart()
func resize_stage() -> void:
	preload("res://scripts/combat/battle_stage.gd").fit(container,get_viewport_rect().size-Vector2(0,30))
	container.position.y += 30
	container.get_parent().get_node("BattleBackdrop").size = get_viewport_rect().size
	container.get_parent().get_node("BattleCurtain").size = get_viewport_rect().size
func restart() -> void:
	host.combat = preload("res://scripts/combat/portugal_rules.gd").new() if encounter.begins_with("child_") else preload("res://scripts/combat/campaign_rules.gd").new()
	host.tactical.setup(host,host.combat)
	host.select_battle_map(battle_map if battle_map!="auto" else ("plaza_child" if encounter.begins_with("child_") else ("plaza" if encounter=="duel" else "courtyard")))
	var hero_name: String = CampaignProfile.hero_name if not CampaignProfile.hero_name.is_empty() else "Aprendiz"
	if encounter.begins_with("child_"): host.begin(0 if encounter=="child_attack" else 1,hero_name)
	else: host.begin_encounter(encounter,hero_name,style)
	# Revisit the ability at its canonical teaching point, even with a later save loaded.
	host.combat.perfect_defense_enabled = encounter in ["perfect_defense","duarte_support"]
	hints.text = "R · repetir     F1 · escolher encontro e manejo"
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_R: restart(); get_viewport().set_input_as_handled()
		elif event.keycode==KEY_F1: host.paused = true; menu.position = Vector2i(30,50); menu.popup(); get_viewport().set_input_as_handled()
