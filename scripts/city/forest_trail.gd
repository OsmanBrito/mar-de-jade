extends Node2D
## Ground clues keep their direction and remain readable on the way home.
var progress
var signs:=false
func _ready() -> void:
	z_index=-2;progress=get_node("/root/ChapterProgress");signs=progress.choices.get("hunt_departure","")=="signs"
func _process(_delta:float) -> void:
	var now:bool=progress.choices.get("hunt_departure","")=="signs"
	if now!=signs:signs=now;queue_redraw()
func hoof(at:Vector2,direction:Vector2) -> void:
	draw_set_transform(at,direction.angle()+PI*.5,Vector2.ONE)
	draw_line(Vector2(-3,-4),Vector2(-3,3),Color("5e5140"),2.4,true)
	draw_line(Vector2(3,-4),Vector2(3,3),Color("5e5140"),2.4,true)
	draw_set_transform(Vector2.ZERO)
func _draw() -> void:
	var path:=[Vector2(620,1030),Vector2(820,1030),Vector2(1000,720)]
	for i in path.size()-1:
		for n in 4:hoof(path[i].lerp(path[i+1],float(n)/4),path[i+1]-path[i])
	for n in 6:hoof(Vector2(2430-n*12,650-n*43),Vector2(-12,-43))
	# A wide paw and narrow hooves can be compared at the optional bank clue.
	for n in 3:
		var at:=Vector2(1810+n*29,1230)
		draw_circle(at,5,Color("655942"))
		for toe in 3:draw_circle(at+Vector2(-5+toe*5,-7),2,Color("655942"))
	if signs:
		for at in [Vector2(820,1050),Vector2(1320,730),Vector2(2010,920)]:
			draw_circle(at,6,Color("a49c7b"));draw_line(at+Vector2(8,5),at+Vector2(25,-6),Color("5c4930"),3,true)
