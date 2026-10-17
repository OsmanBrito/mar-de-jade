extends RefCounted
## Shared materials and type for campaign, conversations and combat.
const INK := Color("132c30")
const EDGE := Color("61756b")
const PAPER := Color("eee4cb")
const GOLD := Color("d9bc80")
const MUTED := Color("a6b6aa")

static func panel(fill: Color = INK, edge: Color = EDGE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(edge,0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.015,0.035,0.035,0.3)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0,3)
	style.set_content_margin_all(18)
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 17
	result.set_color("font_color","Label",PAPER)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var fill := Color("24453f") if state in ["hover","pressed"] else INK
		var edge := GOLD if state in ["hover","focus"] else EDGE
		var style := panel(fill,edge)
		style.shadow_size = 0
		style.set_content_margin_all(10)
		result.set_stylebox(state,"Button",style)
	result.set_color("font_color","Button",PAPER)
	result.set_color("font_hover_color","Button",Color("fff2d1"))
	result.set_color("font_focus_color","Button",Color("fff2d1"))
	result.set_color("font_disabled_color","Button",Color("71867d"))
	for state in ["normal","focus","read_only"]:
		var field := panel(Color("0c2227"),GOLD if state=="focus" else EDGE)
		field.shadow_size = 0
		field.set_content_margin_all(12)
		result.set_stylebox(state,"LineEdit",field)
	result.set_color("font_color","LineEdit",PAPER)
	result.set_color("caret_color","LineEdit",GOLD)
	result.set_color("selection_color","LineEdit",Color("355c50"))
	result.set_color("font_placeholder_color","LineEdit",MUTED)
	var track := panel(Color("0b2026"),Color("0b2026"))
	track.shadow_size = 0; track.set_content_margin_all(0)
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = Color("78b9a0"); fill.border_color = fill.bg_color
	result.set_stylebox("background","ProgressBar",track)
	result.set_stylebox("fill","ProgressBar",fill)
	result.set_constant("outline_size","Label",0)
	return result
