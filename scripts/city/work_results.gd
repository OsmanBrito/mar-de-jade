extends Node2D
## Physical results are derived from quest state, and survive every map reload.
var kind := ""
static func apply(world,p) -> void:
 var specs: Array = [
  ["CarroDaOficina","C01-LIS-01","cart","Roda firme · carga pronta"],
  ["BancaDePeixe","C01-LIS-02","account","Entrega conferida · 5 + 2"],
  ["TrabalhadorDoPontao","C01-LIS-03","kit","Reserva pessoal conferida"],
  ["AmarraDoBatel","C01-LIS-04","rope","Amarra com folga"]
 ]
 for spec in specs:
  var anchor=world.sorted_world.get_node_or_null(spec[0])
  if anchor==null: continue
  var mark=anchor.get_node_or_null("WorkResult")
  if mark==null:
   mark=new();mark.name="WorkResult";mark.kind=spec[2];mark.position=Vector2(30,8)
   anchor.add_child(mark)
  mark.visible=p.local_requests.get(spec[1],"")=="completed"
func _draw() -> void:
 draw_set_transform(Vector2(8,0),0,Vector2(1,.35))
 for ring in range(3,0,-1):draw_circle(Vector2.ZERO,15+ring*2,Color(0,0,0,.035))
 draw_set_transform(Vector2.ZERO)
 if kind=="cart":
  draw_rect(Rect2(-10,-18,23,18),Color("876a45"))
  for x in [-5,5]:draw_line(Vector2(x,-17),Vector2(x,0),Color("bd9d69"),1,true)
  draw_line(Vector2(-13,2),Vector2(18,2),Color("c0aa7f"),3,true)
 elif kind=="account":
  draw_rect(Rect2(-10,-15,25,16),Color("d6c6a0"))
  draw_string(ThemeDB.fallback_font,Vector2(-7,-3),"5+2",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("344e42"))
  draw_circle(Vector2(12,-13),4,Color("8e5945"))
 elif kind=="kit":
  draw_colored_polygon(PackedVector2Array([Vector2(-9,0),Vector2(-8,-14),Vector2(9,-14),Vector2(12,0)]),Color("6b5a3c"))
  draw_rect(Rect2(-7,-12,7,9),Color("daceac"));draw_circle(Vector2(6,-9),4,Color("68817b"))
 else:
  for i in 3:draw_arc(Vector2(4,0),12+i*2,0,TAU,26,Color("b69a71"),1.4,true)
