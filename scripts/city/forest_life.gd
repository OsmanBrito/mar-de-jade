extends Node2D
## Only moving details redraw; the terrain stays cached by Godot.
const Plan = preload("res://scripts/city/forest_plan.gd")
var world
var clock := 0.0
var redraw_clock := 0.0
func _process(delta: float) -> void:
	clock += delta; redraw_clock += delta
	if redraw_clock>.08: redraw_clock = 0; queue_redraw()
func _draw() -> void:
	var reduced: bool = get_node("/root/GamePreferences").options.get("reduced_fx",false)
	var time := 0.0 if reduced else clock
	for i in 28:
		var y := -200+i*76.0+fmod(time*12,76)
		if y>630 and y<815: continue
		var left := bank_at(y,true); var right := bank_at(y,false)
		var at := left.lerp(right,.45+.12*sin(i*2.1))
		draw_polyline(PackedVector2Array([at+Vector2(-12,1),at,at+Vector2(12,-1)]),Color(.74,.85,.73,.18),1.4,true)
	# Small distant birds cross clearings; movement stops with the world's pause.
	for i in 3:
		var at := Vector2(520+fmod(time*22+i*830,2100),390+sin(time*.17+i)*95+i*160)
		var wing := 2.0 if reduced else sin(time*7+i)*3
		draw_polyline(PackedVector2Array([at+Vector2(-5,-wing),at,at+Vector2(5,-wing)]),Color(.19,.23,.17,.7),1.5,true)
static func bank_at(y: float,left: bool) -> Vector2:
	var bank: Array = Plan.WATER.slice(0,8) if left else Plan.WATER.slice(8,16)
	if not left: bank.reverse()
	for i in bank.size()-1:
		var a: Vector2 = bank[i]; var b: Vector2 = bank[i+1]
		if y>=a.y and y<=b.y: return a.lerp(b,inverse_lerp(a.y,b.y,y))
	return Vector2(1400 if left else 1520,y)
