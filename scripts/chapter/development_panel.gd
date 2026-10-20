extends VBoxContainer
## Shared land/ship editor. Everything is a draft until the explicit commit.
signal committed(data: Dictionary)
const Dev = preload("res://scripts/chapter/character_development.gd")
const Items = preload("res://scripts/chapter/player_items.gd")
var original: Dictionary = {}
var pending: Dictionary = {}
var person := "hero"
var allowed := false
var attribute_buttons: Dictionary = {}
var commit_button: Button
var names: Dictionary = {}
func setup(data: Dictionary,safe: bool) -> void:
	original = data.duplicate(true); pending = data.duplicate(true); Dev.ensure(pending); allowed = safe
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/skill_icons.json")).skills: names[row.id] = row.name
	add_theme_constant_override("separation",10); render()
func text(value: String,size := 17,color := Color("c4d7cc"),parent: Node = self) -> Label:
	var node := Label.new(); node.text = value; node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL; node.add_theme_font_size_override("font_size",GamePreferences.font_size(size)); node.add_theme_color_override("font_color",color); parent.add_child(node); return node
func action(value: String,callback: Callable,parent: Node = self) -> Button:
	var node := Button.new(); node.text = value; node.custom_minimum_size.y = 42; node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; node.add_theme_font_size_override("font_size",GamePreferences.font_size(17)); node.pressed.connect(callback); parent.add_child(node); return node
func render() -> void:
	var scroll: ScrollContainer = null
	var ancestor = get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer: scroll = ancestor; break
		ancestor = ancestor.get_parent()
	var previous_scroll: int = scroll.scroll_vertical if scroll!=null else 0
	for child in get_children(): remove_child(child); child.queue_free()
	attribute_buttons.clear()
	var navigation := HBoxContainer.new(); add_child(navigation)
	for id in pending.development.members:
		action(pending.get("hero_name","Protagonista") if id=="hero" else "Duarte",func(): person = id; render(),navigation)
	var r: Dictionary = Dev.member(pending,person)
	var level := Dev.level_of(int(r.xp)); var cultivation: Dictionary = r.cultivation
	text("Nível %d · %s %d"%[level,Dev.RANKS[int(cultivation.rank)],cultivation.step],24,Color("e6cb8d"))
	text("XP %d / %d para o próximo nível"%[int(r.xp)-Dev.threshold(level),Dev.xp_to_next(level)] if level<60 else "Nível máximo · 60")
	text("Pontos disponíveis: %d · distribuição manual"%Dev.available_points(r),19,Color("8cd7b7"))
	if not allowed: text("Consulta disponível. Procura um local seguro, fora de tarefas urgentes ou combate, para alterar a preparação.",16,Color("e6cb8d"))
	var review := HBoxContainer.new(); review.add_theme_constant_override("separation",8); add_child(review)
	commit_button = action("Confirmar alterações",commit,review)
	commit_button.disabled = not allowed or pending.development==original.get("development",{})
	action("Descartar prévia",func(): pending = original.duplicate(true); Dev.ensure(pending); render(),review)
	text("Atributos · prévia",21,Color("e6cb8d"))
	for key in Dev.ATTRIBUTES:
		var line := HBoxContainer.new(); line.add_theme_constant_override("separation",10); add_child(line)
		var title := text(Dev.ATTRIBUTES[key],17,Color("e8dfc8"),line); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var minus := action("−",change_attribute.bind(key,-1),line); minus.size_flags_horizontal = Control.SIZE_SHRINK_END; minus.custom_minimum_size.x = 44; minus.disabled = not allowed or int(r.attributes[key])<=5
		var value := text(str(int(r.attributes[key])),20,Color("e6cb8d"),line); value.custom_minimum_size.x = 30; value.size_flags_horizontal = Control.SIZE_SHRINK_END; value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var plus := action("+",change_attribute.bind(key,1),line); plus.size_flags_horizontal = Control.SIZE_SHRINK_END; plus.custom_minimum_size.x = 44; plus.disabled = not allowed or int(r.attributes[key])>=60 or Dev.available_points(r)<=0
		attribute_buttons[key] = {"plus":plus,"minus":minus}
	var before: Dictionary = Items.stats(original) if person=="hero" else Dev.base_stats(original,person)
	var after: Dictionary = Items.stats(pending) if person=="hero" else Dev.base_stats(pending,person)
	var preview := ""
	for key in ["hp","qi","posture","defense","speed"]: preview += "%s: %d → %d\n"%[Items.STAT_NAMES[key],before[key],after[key]]
	var style: String = pending.style if person=="hero" else "LA"
	preview += "Potência básica (%s): %.0f → %.0f\nMovimento: 5 casas"%["/".join(Dev.INFLUENCES[style]),before.get("power",floor(Dev.power(original,style,person))),after.get("power",floor(Dev.power(pending,style,person)))]
	text(preview,17)
	var base: Dictionary = Dev.base_stats(pending,person)
	var life_level: int = 10*(level-1)
	var energy_level: int = int((level-1)/3)
	text("Vida: 100 base + %d nível + %d Vigor + %d equipamento\nAlento: 20 base + %d nível + %d Espírito + %d equipamento"%[life_level,int(base.hp)-100-life_level,int(after.hp)-int(base.hp),energy_level,int(base.qi)-20-energy_level,int(after.qi)-int(base.qi)],15)
	text("A prévia não altera o personagem. Redistribuir é gratuito e não recupera vida ou alento.",15)
	action("Redistribuir pontos na prévia",func():
		for key in Dev.ATTRIBUTES: r.attributes[key] = 5
		render()).disabled = not allowed
	var slots: Array = r.active_skills
	text("Técnicas preparadas · %d/6"%slots.size(),21,Color("e6cb8d"))
	text("Em combate aparecem apenas as técnicas compatíveis com a arma equipada. A prática é registrada após a vitória.",15)
	for id in pending.skills:
		if Dev.Content.owner(id)!=person or id=="DP01" or not Dev.Content.executable(id): continue
		var rank := Dev.grade(pending,id,person)
		var node := action(("✓ " if slots.has(id) else "+ ")+names.get(id,id)+" · Grau "+["I","II","III"][rank-1]+" · %d/%d"%[int(r.practice.get(id,0)),8 if rank==1 else 20],func(): Dev.toggle_skill(pending,id); render())
		node.disabled = not allowed or (not slots.has(id) and slots.size()>=6)
	if person=="hero" and pending.skills.has("DP01"): text("Defesa Perfeita · reação aprendida; não ocupa vaga ativa.",15)
	text("Proficiência por manejo",21,Color("e6cb8d"))
	for style_id in Dev.STYLES: text("%s · %d/1000"%[Items.STYLES[style_id],r.proficiency[style_id]],16)
	text("Treinos livres não concedem XP nem prática ilimitada. Cultivo avança por provas da história.",15)
	if scroll!=null: scroll.set_deferred("scroll_vertical",previous_scroll)
func change_attribute(key: String,delta: int) -> void:
	if not allowed: return
	var r: Dictionary = Dev.member(pending,person)
	if delta>0 and (Dev.available_points(r)<=0 or int(r.attributes[key])>=60): return
	if delta<0 and int(r.attributes[key])<=5: return
	r.attributes[key] = int(r.attributes[key])+delta
	render()
	if delta>0 and not attribute_buttons[key].plus.disabled: attribute_buttons[key].plus.grab_focus()
	else: attribute_buttons[key].minus.grab_focus()
func commit() -> void:
	if not allowed or not Dev.valid(pending.development,pending.skills): return
	Items.clamp_vitals(pending)
	for id in pending.get("companion_vitals",{}):
		var limits := preload("res://scripts/chapter/party_resources.gd").limits(id,pending)
		for key in limits: pending.companion_vitals[id][key] = mini(int(pending.companion_vitals[id][key]),int(limits[key]))
	committed.emit(pending.duplicate(true))
