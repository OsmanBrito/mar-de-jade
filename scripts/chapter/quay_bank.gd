extends RefCounted
## Adapted from Mar de Ferro's bruma_terrain.gd: dry face, damp band and submerged footing.
const DRY := 36.0
const WET := 46.0
const SUBMERGED := 60.0
const PERIOD := 136.0
const PATH := "res://assets/art/living-quay/mar-de-ferro-bank-masonry-v1.png"
static var masonry: CanvasTexture
static func texture() -> Texture2D:
	if masonry == null:
		masonry = CanvasTexture.new()
		masonry.diffuse_texture = load(PATH) if ResourceLoader.exists(PATH) else ImageTexture.create_from_image(Image.load_from_file(PATH))
		masonry.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		masonry.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	return masonry
static func band(canvas: CanvasItem,a: Vector2,b: Vector2,top: float,bottom: float,v0: float,v1: float,upper: Color,lower: Color) -> void:
	var tangent := Vector2(-2,1).normalized()
	var u0 := a.dot(tangent)/PERIOD; var u1 := b.dot(tangent)/PERIOD
	var points := PackedVector2Array([a+Vector2(0,top),b+Vector2(0,top),b+Vector2(0,bottom),a+Vector2(0,bottom)])
	canvas.draw_polygon(points,PackedColorArray([upper,upper,lower,lower]),PackedVector2Array([Vector2(u0,v0),Vector2(u1,v0),Vector2(u1,v1),Vector2(u0,v1)]),texture())
static func draw(canvas: CanvasItem,a: Vector2,b: Vector2) -> void:
	band(canvas,a,b,0,DRY,0,0.78,Color(0.81,0.79,0.71),Color(0.57,0.63,0.52))
	band(canvas,a,b,DRY,WET,0.78,1.0,Color(0.49,0.60,0.48),Color(0.27,0.48,0.43,0.88))
	band(canvas,a,b,WET,SUBMERGED,1.0,1.25,Color(0.25,0.48,0.45,0.45),Color(0.20,0.47,0.48,0))
	var wet_a := a+Vector2(0,WET); var wet_b := b+Vector2(0,WET)
	canvas.draw_polygon(PackedVector2Array([wet_a,wet_b,wet_b+Vector2(8,10),wet_a+Vector2(8,10)]),PackedColorArray([Color(0.02,0.13,0.14,0.22),Color(0.02,0.13,0.14,0.22),Color.TRANSPARENT,Color.TRANSPARENT]))
	canvas.draw_line(a,b,Color("b7ac8c"),2,true)
