shader_type canvas_item;
// Drop-in material for TileMapLayers using data/terrain/ground.tres.
// Each tile keeps its cell and diamond mask (from the 256x128 thumbnail), but its
// colour comes from the full-resolution terrain atlas sampled in world space, so
// stone and boards no longer repeat as a tiny checker per cell.
uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
uniform float stone_period = 230.0;
uniform float wood_period = 256.0;
// Optional: hide paving below the quay edge seen from the departing ship.
uniform bool clip_to_shore = false;
varying vec2 world_at;

const vec2 ATLAS = vec2(1774.0, 887.0);
const vec2 HALF = vec2(441.0, 219.5);
// Top corner of each diamond in the atlas, matching the thumbnail quadrants.
const vec2 TOPS[4] = vec2[4](vec2(443.5, 2.0), vec2(1330.5, 2.0), vec2(443.5, 446.0), vec2(1330.5, 446.0));

void vertex() { world_at = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { return noise(p) * 0.55 + noise(p * 2.13 + 7.1) * 0.3 + noise(p * 4.7 - 3.3) * 0.15; }
vec2 iso(vec2 p, float size) { return vec2(p.x / size + 2.0 * p.y / size, -p.x / size + 2.0 * p.y / size); }

vec4 diamond(vec2 uv, vec2 top) {
	vec2 f = mix(vec2(0.012), vec2(0.988), fract(uv));
	vec2 right = HALF; vec2 left = vec2(-HALF.x, HALF.y);
	vec2 dx = dFdx(uv); vec2 dy = dFdy(uv);
	return textureGrad(atlas, (top + f.x * right + f.y * left) / ATLAS,
		(dx.x * right + dx.y * left) / ATLAS, (dy.x * right + dy.y * left) / ATLAS);
}
float seam(vec2 uv) { vec2 f = fract(uv); return smoothstep(0.0, 0.07, min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y))); }

// Two offset layers hide the diamond seams and break up repetition (stone, earth).
vec3 layered(vec2 p, vec2 top, float size) {
	vec2 a = iso(p, size);
	vec2 b = iso(p + vec2(size * 0.37, size * 0.11), size) + vec2(0.5);
	float n = fbm(p / 520.0);
	float wa = seam(a) * (0.25 + n);
	float wb = seam(b) * (1.25 - n);
	return (diamond(a, top).rgb * wa + diamond(b, top).rgb * wb) / max(wa + wb, 0.001);
}

void fragment() {
	if (clip_to_shore && world_at.y > 45.0 + (world_at.x + 700.0) * 210.0 / 1240.0) discard;
	vec4 mask = texture(TEXTURE, UV);
	int kind = int(floor(UV.x * 2.0)) + 2 * int(floor(UV.y * 2.0));
	vec2 p = world_at;
	vec3 col;
	if (kind == 1 || kind == 3) {
		// Boards keep one continuous plank pattern; blending would ghost the planks.
		col = diamond(iso(p, wood_period), TOPS[kind]).rgb;
		col *= 0.92 + fbm(p / 300.0) * 0.14;
	} else {
		col = layered(p, TOPS[kind], kind == 0 ? stone_period : stone_period * 0.8);
		col *= 0.9 + fbm(p / 260.0) * 0.18;
	}
	COLOR = vec4(col * vec3(1.0, 0.985, 0.95), mask.a);
}
