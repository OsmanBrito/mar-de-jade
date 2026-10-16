extends RefCounted
## Portugal's original projection and cell size; only the enemy deck is playable.
const Board = preload("res://scripts/combat/portugal_board.gd")
const SIZE := Vector2i(9,4)
const FRIENDLY_OFFSET := Vector2(0,5.55)
static func point(x: float,y: float) -> Vector2:
	return Board.ORIGIN+Vector2((x-y)*Board.STEP.x,(x+y)*Board.STEP.y)
static func outline(offset: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in [Vector2(-1.25,-0.1),Vector2(-0.65,-0.85),Vector2(8.8,-0.85),Vector2(10.1,1.5),Vector2(8.8,3.85),Vector2(-0.65,3.85),Vector2(-1.25,3.1)]:
		result.append(point(p.x+offset.x,p.y+offset.y))
	return result
