extends Node2D
signal lesson_completed(success: bool)
signal practice_aborted
var allow_practice_exit := false
var pause_selection := 0
const Rules = preload("res://scripts/combat/portugal_rules.gd")
const View = preload("res://scripts/combat/portugal_view.gd")
class Locale:
	extends RefCounted
	func text(value: String) -> String: return value
var combat = Rules.new()
var tactical = View.new()
var font: Font = ThemeDB.fallback_font
var localization = Locale.new()
var progress := {"data":{"options":{"wide_timing":false,"difficulty":"normal","reduced_fx":false,"fast_combat":false}}}
var flags := {"training":true,"prologue":true}
var practice_mode := true
var buttons: Array = []
var art := {"hero_frames":{},"ActorCatalog":{"NAMED_COMBAT":{}}}
var time := 0.0
var active := false
var paused := false:
	set(value):
		paused = value
		for voice in effect_players: voice.stream_paused = value
var completed := false
var ending = preload("res://scripts/combat/battle_ending.gd").new()
var note := ""
var audio: AudioStreamPlayer
var combat_audio = preload("res://scripts/combat/portugal_audio.gd").new()
var effect_players: Array[AudioStreamPlayer] = []
var effect_cursor := 0
var battle_map_id := "courtyard"

func select_battle_map(map_id: String) -> void:
	# Only a map identifier crosses this boundary, never exploration nodes.
	assert(preload("res://scripts/combat/battle_maps.gd").has_map(map_id),"Missing battle map: "+map_id)
	battle_map_id = map_id
	tactical.arena.map_id = map_id

func prepare_battle_map() -> void:
	# The naval runtime already owns an authored, larger deck and its obstacles.
	if combat.encounter=="atlantic_boarding": return
	tactical.arena.map_id = battle_map_id
	preload("res://scripts/combat/battle_maps.gd").apply_obstacles(combat,battle_map_id)

func _ready() -> void:
	progress.data.options = GamePreferences.options.duplicate()
	GamePreferences.changed.connect(func(): progress.data.options = GamePreferences.options.duplicate())
	for i in 6:
		var voice := AudioStreamPlayer.new(); voice.volume_db = -17; voice.bus = GamePreferences.effects_bus; add_child(voice); effect_players.append(voice)
	audio = effect_players[0]
	tactical.setup(self,combat)

func begin(id: int, hero_name: String) -> void:
	ending.reset(self)
	combat.start_lesson(id,hero_name)
	prepare_battle_map()
	completed = false; active = true; paused = false; note = ""
	tactical.begin()
	queue_redraw()

func check_outcome() -> bool:
	if completed: return true
	var result: Dictionary = combat.lesson_result()
	if result.finished:
		completed = true; active = false
		ending.begin(self,result.success)
		return true
	return false

func _process(delta: float) -> void:
	if active and not paused:
		time += delta
		tactical.update(delta)
	elif ending.running() and not paused:
		update_ending(delta)
	queue_redraw()

func update_ending(delta: float) -> void:
	ending.advance(self,delta)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var translated: InputEventKey = event.duplicate()
		translated.physical_keycode = GamePreferences.combat_key(event.physical_keycode); event = translated
	if event is InputEventMouse:
		event = event.xformed_by(get_viewport().canvas_transform.affine_inverse())
	if allow_practice_exit and (active or ending.phase in ["hold","out"]):
		var exit_key: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_R
		var exit_pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_BACK
		var exit_click: bool = event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and Rect2(730,77,214,30).has_point(event.position)
		if exit_key or exit_pad or exit_click:
			abort_practice(); get_viewport().set_input_as_handled(); return
	if paused and (active or ending.phase=="hold"):
		if _pause_input(event): get_viewport().set_input_as_handled()
		return
	if ending.running() or completed:
		if ending.phase=="hold" and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START)):
			paused = not paused; get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_A): get_viewport().set_input_as_handled()
		return
	if not active: return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		if not tactical.cancel(): paused = not paused
		get_viewport().set_input_as_handled()
	elif not paused:
		# The same reference keyboard/mouse path; controller maps to its keys.
		if event is InputEventJoypadButton and event.pressed:
			var key = InputEventKey.new()
			key.pressed = true
			var techniques: Array = combat.commands(combat.current_id).filter(func(action): return action>0)
			if event.button_index==JOY_BUTTON_Y and techniques.is_empty():
				notify_player("Nenhuma técnica preparada para este manejo. O básico continua disponível."); return
			var practice_skill: int = 1
			if not techniques.is_empty():
				var selected: int = techniques.find(tactical.selected_skill)
				var next_action: int = techniques[(selected+1)%techniques.size()]
				practice_skill = combat.commands(combat.current_id).find(next_action)
			key.physical_keycode = {JOY_BUTTON_A:KEY_SPACE if tactical.phase.begins_with("timing") else KEY_ENTER,JOY_BUTTON_B:KEY_ESCAPE,JOY_BUTTON_X:KEY_1,JOY_BUTTON_Y:KEY_1+practice_skill,JOY_BUTTON_LEFT_STICK:KEY_F,JOY_BUTTON_RIGHT_STICK:KEY_Z,JOY_BUTTON_BACK:KEY_9,JOY_BUTTON_LEFT_SHOULDER:KEY_Q if tactical.phase=="facing" else KEY_G,JOY_BUTTON_RIGHT_SHOULDER:KEY_E if tactical.phase=="facing" else KEY_T,JOY_BUTTON_DPAD_LEFT:KEY_LEFT,JOY_BUTTON_DPAD_RIGHT:KEY_RIGHT,JOY_BUTTON_DPAD_UP:KEY_UP,JOY_BUTTON_DPAD_DOWN:KEY_DOWN}.get(event.button_index,0)
			if key.physical_keycode == KEY_ESCAPE: tactical.cancel()
			else: tactical.input_event(key)
		else: tactical.input_event(event)

func _draw() -> void:
	var container := get_viewport().get_parent() as Control
	if container!=null and not container.visible: return
	if combat.current_id < 0: return
	buttons.clear()
	tactical.draw()
	if paused:
		draw_rect(Rect2(0,0,960,540),Color(0.01,0.04,0.06,0.85))
		centered("COMBATE EM PAUSA",154,24,Color("eddfbb"))
		var rows := ["Retomar · Esc / Start","Janela de timing ampliada","Reduzir efeitos e movimento","Animações rápidas"]
		for i in rows.size():
			var key: String = ["","wide_timing","reduced_fx","fast_combat"][i]
			var prefix := "▶ " if i==pause_selection else ""
			button("pause_%d"%i,prefix+rows[i]+(" · ligada" if GamePreferences.options.get(key,false) else " · desligada" if i>0 else ""),Rect2(265,185+i*54,430,45))
		centered("Setas / direcional · escolher     Enter / A · alterar",438,13,Color("eddfbb"))
	if allow_practice_exit and (active or ending.phase in ["hold","out"]):
		button("practice_exit","R / Select · sair do treino",Rect2(730,77,214,30))

func _pause_input(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_START,JOY_BUTTON_B]): paused = false; return true
	var key := 0
	if event is InputEventKey and event.pressed and not event.echo: key = event.physical_keycode
	if event is InputEventJoypadButton and event.pressed: key = {JOY_BUTTON_DPAD_UP:KEY_UP,JOY_BUTTON_DPAD_DOWN:KEY_DOWN,JOY_BUTTON_A:KEY_ENTER}.get(event.button_index,0)
	if key in [KEY_UP,KEY_DOWN]: pause_selection = posmod(pause_selection+(-1 if key==KEY_UP else 1),4); return true
	var activate := key in [KEY_ENTER,KEY_SPACE]
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		for i in 4:
			if Rect2(265,185+i*54,430,45).has_point(event.position): pause_selection = i; activate = true
	if activate:
		if pause_selection==0: paused = false
		else:
			var option: String = ["","wide_timing","reduced_fx","fast_combat"][pause_selection]
			GamePreferences.set_option(option,not GamePreferences.options[option])
		return true
	return false

func abort_practice() -> void:
	if not allow_practice_exit or not (active or ending.phase in ["hold","out"]): return
	active = false; completed = false; paused = false
	ending.phase = "idle"; ending.has_result = false
	preload("res://scripts/combat/battle_stage.gd").cover(self,0)
	for voice in effect_players: voice.stop()
	tactical.phase = "choose"; tactical.plan.clear(); tactical.result.clear(); tactical.floats.clear()
	practice_aborted.emit()

func notify_player(message: String) -> void:
	note = message
	tactical.log_message(message)

func text_at(value: String, pos: Vector2, size := 16, color := Color("eddfbb")) -> void:
	value = GamePreferences.hint_text(value)
	size = GamePreferences.font_size(size)
	draw_string(font,pos+Vector2(1,1),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(0,0,0,0.18))
	draw_string(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func centered(value: String, y: float, size := 16, color := Color("eddfbb"), center := 480.0) -> void:
	value = GamePreferences.hint_text(value)
	text_at(value,Vector2(center-font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,GamePreferences.font_size(size)).x/2,y),size,color)
func panel(rect: Rect2, color := Color("102c37"), border := Color("42616a")) -> void:
	var style := preload("res://scripts/ui/presentation.gd").panel(color,border)
	draw_style_box(style,rect)
func button(id: String, label: String, rect: Rect2, enabled := true, detail := "") -> void:
	var highlight := rect.has_point(get_global_mouse_position()) and enabled
	panel(rect,Color("284955") if highlight else Color("102c37"),Color("e2b66c") if highlight else Color("42616a"))
	var compact := rect.size.x < 130
	var padding := 10 if compact else 15
	var tight := rect.size.y < 46 and not detail.is_empty()
	var label_size := 12 if tight else (13 if compact else 16)
	var baseline: float = (rect.size.y-font.get_height(label_size))*0.5+font.get_ascent(label_size) if detail.is_empty() else (15.0 if tight else 22.0)
	text_at(fit_text(label,rect.size.x-padding*2,label_size),rect.position+Vector2(padding,baseline),label_size,Color("eddfbb") if enabled else Color("8a9d9e"))
	if not detail.is_empty(): text_at(fit_text(detail,rect.size.x-padding*2,10),rect.position+Vector2(padding,rect.size.y-5),10,Color("9db3af"))
	buttons.append({"id":id,"rect":rect,"enabled":enabled})
func fit_text(value: String, width: float, size: int) -> String:
	value = GamePreferences.hint_text(value)
	size = GamePreferences.font_size(size)
	if font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x <= width: return value
	while not value.is_empty() and font.get_string_size(value+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width: value = value.left(-1)
	return value+"…"
func bar(pos: Vector2, size: Vector2, value: float, maximum: float, color: Color) -> void:
	draw_rect(Rect2(pos,size),Color("0c242e"))
	draw_rect(Rect2(pos,Vector2(size.x*clampf(value/maxf(1,maximum),0,1),size.y)),color)
func play_effect(event: String,gain_db: float = -17,pitch: float = 1.0) -> void:
	if DisplayServer.get_name()=="headless" or effect_players.is_empty(): return
	var voice := effect_players[effect_cursor]; effect_cursor = (effect_cursor+1)%effect_players.size()
	voice.stream = combat_audio.stream(event); voice.volume_db = gain_db; voice.pitch_scale = pitch; voice.stream_paused = paused
	voice.play()
func tone(frequency: float,_seconds: float) -> void:
	play_effect("menu_confirm",-27,0.92 if frequency<400 else 1.10 if frequency>800 else 1.0)
func combat_action_sound(skill: int,actor: int,_stage: String,_plan: Dictionary) -> void:
	var style: String = combat.style if actor==0 and combat.get("style")!=null else "ES"
	play_effect(combat_audio.action_event(style,combat.encounter.begins_with("portugal_child"),skill==4 or (style=="FO" and skill==8)),-19)
func combat_impact_sound(result: Dictionary,_plan: Dictionary,grades: Dictionary) -> void:
	var style: String = combat.style if result.get("actor",-1)==0 and combat.get("style")!=null else "ES"
	for event in combat_audio.impact_events(style,combat.encounter.begins_with("portugal_child"),result,grades): play_effect(event,-17)

func combat_release_sound(style: String,skill: int = 0) -> void:
	var event: String = combat_audio.release_event(style,skill)
	if not event.is_empty(): play_effect(event,-15)




func begin_encounter(mode: String, hero_name: String, style: String) -> void:
	ending.reset(self)
	combat.start_encounter(mode,hero_name,style)
	prepare_battle_map()
	completed = false; active = true; paused = false; note = ""
	tactical.begin()
	queue_redraw()


