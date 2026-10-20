extends Node2D
## Small tools follow work phases; never add collision or move the service point.
var job := ""
var phase := ""
var weight := 0.0
var active := false
func _draw() -> void:
 if not active: return
 var hand:=Vector2(13,-34)
 if job=="workshop" and phase=="trabalhar":
  var angle:=lerpf(-.8,.4,sin(weight*TAU*3)*.5+.5)
  draw_set_transform(hand,angle)
  draw_line(Vector2.ZERO,Vector2(0,-17),Color("806443"),3,true)
  draw_line(Vector2(-7,-18),Vector2(7,-18),Color("abb0a1"),5,true)
 elif job=="keeper" and phase in ["trabalhar","conferir"]:
  draw_arc(hand+Vector2(3,3),8,0,TAU,20,Color("bda278"),3,true)
 elif job=="dock" and phase=="conferir":
  draw_colored_polygon(PackedVector2Array([hand+Vector2(-3,-5),hand+Vector2(12,-3),hand+Vector2(11,9),hand+Vector2(-3,7)]),Color("d5c69d"))
  draw_line(hand+Vector2(0,0),hand+Vector2(8,2),Color("635b43"),1,true)
 elif job in ["fisher","neighbor"] and phase=="pousar":
  draw_arc(Vector2(15,-18),9,0,PI,18,Color("bfaa7d"),2,true)
 draw_set_transform(Vector2.ZERO)
