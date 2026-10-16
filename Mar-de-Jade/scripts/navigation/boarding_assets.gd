extends RefCounted
## Exact Mar de Ferro source art, with its approved smooth filtering and alpha edges.
const ROOT := "res://assets/art/combat/boarding/"
static var manifest: Dictionary = {}
static var textures: Dictionary = {}
static var images: Dictionary = {}
static var cutouts: Dictionary = {}
static var shadow: Texture2D
static func data() -> Dictionary:
	if manifest.is_empty(): manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"frames.json"))
	return manifest
static func texture(name: String,repeat: bool = false) -> CanvasTexture:
	if textures.has(name): return textures[name]
	var source: Texture2D = load(ROOT+name) if ResourceLoader.exists(ROOT+name) else ImageTexture.create_from_image(Image.load_from_file(ROOT+name))
	var pixels := source.get_image(); pixels.fix_alpha_edges(); pixels.generate_mipmaps()
	images[name] = pixels
	var result := CanvasTexture.new(); result.diffuse_texture = ImageTexture.create_from_image(pixels)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if repeat: result.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	textures[name] = result
	return result
static func prop(key: String) -> AtlasTexture:
	if cutouts.has(key): return cutouts[key]
	var entry: Dictionary = data().props[key]; var r: Array = entry.region
	var result := AtlasTexture.new(); result.atlas = texture(entry.source.get_file())
	result.region = Rect2(r[0],r[1],r[2],r[3]); result.filter_clip = true
	cutouts[key] = result
	return result
static func contact_shadow() -> Texture2D:
	if shadow!=null: return shadow
	var gradient := Gradient.new(); gradient.offsets = PackedFloat32Array([0,0.25,0.6,1])
	gradient.colors = PackedColorArray([Color(0.045,0.065,0.065,0.32),Color(0.045,0.065,0.065,0.23),Color(0.045,0.065,0.065,0.09),Color(0.045,0.065,0.065,0)])
	var radial := GradientTexture2D.new(); radial.gradient = gradient; radial.width = 128; radial.height = 64
	radial.fill = GradientTexture2D.FILL_RADIAL; radial.fill_from = Vector2(0.5,0.5); radial.fill_to = Vector2(1,0.5)
	shadow = radial
	return shadow
