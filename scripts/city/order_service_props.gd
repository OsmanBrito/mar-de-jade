extends Node2D
const Dining=preload("res://scripts/chapter/dining_art.gd")
var kind := "floor"
func _draw() -> void:
 if kind=="chapter":
  draw_colored_polygon(PackedVector2Array([Vector2(-65,-85),Vector2(35,-88),Vector2(44,-51),Vector2(-57,-48)]),Color("dfcda0"))
  draw_polyline(PackedVector2Array([Vector2(-55,-78),Vector2(-35,-72),Vector2(-25,-77),Vector2(-10,-66),Vector2(20,-61)]),Color("7e9b9a"),3,true)
  draw_polyline(PackedVector2Array([Vector2(-49,-63),Vector2(-23,-59),Vector2(4,-75),Vector2(28,-69)]),Color("9b5246"),1.5,true)
  for at in [Vector2(-49,-63),Vector2(-23,-59),Vector2(4,-75),Vector2(28,-69)]:draw_circle(at,2,Color("78573e"))
  draw_rect(Rect2(48,-76,25,17),Color("e1d0a3"));draw_circle(Vector2(62,-65),3,Color("984d43"))
 elif kind=="registry":
  for offset in [Vector2(-35,-52),Vector2(0,-54),Vector2(35,-52)]:
   draw_colored_polygon(PackedVector2Array([offset+Vector2(-15,-20),offset+Vector2(14,-23),offset+Vector2(17,0),offset+Vector2(-13,3)]),Color("e1d0a3"))
   for line in 3:draw_line(offset+Vector2(-10,line*3-3),offset+Vector2(9,line*3-3),Color("796447"),1,true)
  Dining.draw(self,"cup",Vector2(50,-47),14)
 elif kind=="armory":
  draw_line(Vector2(-37,-65),Vector2(38,-77),Color(.16,.12,.08,.4),6,true)
  draw_line(Vector2(-37,-68),Vector2(-20,-71),Color("60442c"),5,true)
  draw_line(Vector2(-20,-71),Vector2(38,-80),Color("b4b8ad"),3,true)
  draw_line(Vector2(-23,-79),Vector2(-20,-63),Color("97865b"),3,true)
 elif kind=="portions":
  for at in [Vector2(-23,-47),Vector2(16,-47),Vector2(-23,-65),Vector2(16,-65)]:
   Dining.draw(self,"bread",at,20)
 else:
  # Compact activity islands anchor large floor planes without blocking navigation.
  for rect in [Rect2(425,600,105,70),Rect2(1130,75,120,55),Rect2(-300,390,95,70)]:
   draw_rect(rect,Color(.5,.39,.22,.12))
