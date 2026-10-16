extends RefCounted
## Presentation geometry is independent of the inherited 9x8 rules and movement costs.
const ORIGIN := Vector2(590,134)
const STEP := Vector2(34,16.5)
static func screen(cell: Vector2i) -> Vector2:
	return ORIGIN+Vector2((cell.x-cell.y)*STEP.x,(cell.x+cell.y)*STEP.y)
static func cell_at(point: Vector2) -> Vector2i:
	var local := point-ORIGIN
	return Vector2i(roundi((local.x/STEP.x+local.y/STEP.y)*0.5),roundi((local.y/STEP.y-local.x/STEP.x)*0.5))
static func polygon(cell: Vector2i,inset: float = 0) -> PackedVector2Array:
	var p := screen(cell)
	return PackedVector2Array([p+Vector2(0,-STEP.y+inset),p+Vector2(STEP.x-inset,0),p+Vector2(0,STEP.y-inset),p+Vector2(-STEP.x+inset,0)])
