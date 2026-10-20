extends Node2D
## Edge landmarks identify both public descents without adding obstacles.
const POINTS := {"wheel":Vector2(-950,600),"ropes":Vector2(1725,700)}
static func location(at: Vector2) -> String:
 if at.x< -750 and at.y>300:return "Lisboa · Rua da roda · estaleiro e pontão poente"
 if at.x>1500 and at.y>400 and at.y<1000:return "Lisboa · Rua das cordas · armazém e oficina"
 return ""
var kind:=""
func _ready() -> void:
 if not kind.is_empty():return
 for id in POINTS:
  var detail=new();detail.name="StreetLandmark_"+id;detail.kind=id;detail.position=POINTS[id]
  get_parent().add_child.call_deferred(detail)
func _draw() -> void:
 if kind=="wheel":draw_wheel()
 elif kind=="ropes":draw_ropes()
func draw_wheel() -> void:
 var wheel:=Vector2.ZERO
 draw_set_transform(wheel,0,Vector2(1,.7))
 for ring in range(3,0,-1):draw_circle(Vector2(8,26),28+ring*3,Color(0,0,0,.04))
 draw_arc(Vector2.ZERO,27,0,TAU,36,Color("694b31"),7,true)
 draw_arc(Vector2.ZERO,25,0,TAU,36,Color("b29465"),2,true)
 for n in 8:draw_line(Vector2.ZERO,Vector2.from_angle(n*TAU/8)*24,Color("9d7e51"),3,true)
 draw_circle(Vector2.ZERO,6,Color("604933"))
 draw_set_transform(Vector2.ZERO)
func draw_ropes() -> void:
 var rope:=Vector2.ZERO
 draw_line(rope+Vector2(0,10),rope+Vector2(0,-80),Color("69533a"),9,true)
 draw_line(rope+Vector2(-26,-65),rope+Vector2(26,-65),Color("a5895a"),6,true)
 for n in 3:
  var center:=rope+Vector2(-18+n*18,-32)
  draw_arc(center,7,0,TAU,24,Color("c9b184"),3,true)
  draw_line(center+Vector2(-6,0),center+Vector2(-6,25+n*3),Color("b99d72"),2,true)
