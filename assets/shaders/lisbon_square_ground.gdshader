shader_type canvas_item;
// Lisbon square paving painted from the full-resolution terrain atlas.
// The old tiles sampled a 128x64 thumbnail of the same art, repeated per cell.
uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
uniform float period = 230.0;       // world width covered by one paving diamond
uniform vec2 square_center = vec2(0.0, 288.0);
uniform vec2 square_half = vec2(640.0, 320.0);
varying vec2 world_at;

const vec2 ATLAS = vec2(1774.0, 887.0);
// Diamond corners in the atlas: flagstones (top-left) and packed earth (bottom-left).
const vec2 STONE_TOP = vec2(443.5, 2.0);
const vec2 EARTH_TOP = vec2(443.5, 446.0);
const vec2 HALF = vec2(441.0, 219.5);

void vertex() { world_at = VERTEX; }

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { return noise(p) * 0.55 + noise(p * 2.13 + 7.1) * 0.3 + noise(p * 4.7 - 3.3) * 0.15; }

vec2 iso(vec2 p, float size) { return vec2(p.x / size + 2.0 * p.y / size, -p.x / size + 2.0 * p.y / size); }

// Samples a diamond with explicit gradients so fract() seams never pick a tiny mip.
vec4 diamond(vec2 uv, vec2 top) {
	vec2 f = mix(vec2(0.012), vec2(0.988), fract(uv));
	vec2 right = vec2(HALF.x, HALF.y);
	vec2 left = vec2(-HALF.x, HALF.y);
	vec2 at = (top + f.x * right + f.y * left) / ATLAS;
	vec2 dx = dFdx(uv); vec2 dy = dFdy(uv);
	vec2 gx = (dx.x * right + dx.y * left) / ATLAS;
	vec2 gy = (dy.x * right + dy.y * left) / ATLAS;
	return textureGrad(atlas, at, gx, gy);
}
float seam(vec2 uv) { vec2 f = fract(uv); return smoothstep(0.0, 0.07, min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y))); }

vec3 layered(vec2 p, vec2 top, float size) {
	vec2 a = iso(p, size);
	vec2 b = iso(p + vec2(size * 0.37, size * 0.11), size) + vec2(0.5);
	float n = fbm(p / 520.0);
	float wa = seam(a) * (0.25 + n);
	float wb = seam(b) * (1.25 - n);
	return (diamond(a, top).rgb * wa + diamond(b, top).rgb * wb) / max(wa + wb, 0.001);
}

void fragment() {
	vec2 p = world_at;
	vec2 rel = (p - square_center) / square_half;
	float inside = abs(rel.x) + abs(rel.y);          // 1.0 on the square's edge
	vec3 stone = layered(p, STONE_TOP, period);
	vec3 earth = layered(p * 1.3, EARTH_TOP, period);
	// Bright, cared-for limestone inside; worn streets with earth in the joints outside.
	float wear = fbm(p / 260.0);
	float street = smoothstep(1.02, 1.25, inside);
	vec3 col = stone * mix(vec3(1.04, 1.0, 0.93), vec3(0.86, 0.84, 0.80), street);
	col = mix(col, earth, street * smoothstep(0.45, 0.8, wear) * 0.55);
	col *= 0.9 + wear * 0.18;
	// Calçada border: a dark basalt band inside a pale limestone kerb.
	float band = smoothstep(0.012, 0.0, abs(inside - 0.955));
	col = mix(col, vec3(0.25, 0.24, 0.22) * (0.85 + noise(p * 0.35) * 0.3), band * 0.85);
	float kerb = smoothstep(0.022, 0.006, abs(inside - 1.012));
	col = mix(col, vec3(0.80, 0.76, 0.66) * (0.9 + noise(p * 0.09) * 0.15), kerb * 0.8);
	// Back façades shade the ground; the city fades away from the square.
	float back = max(0.0, -rel.y) ;
	col *= 1.0 - smoothstep(0.7, 1.0, inside) * smoothstep(0.0, 0.6, back) * 0.18;
	col *= mix(1.0, 0.5, smoothstep(1.5, 3.0, inside));
	col *= vec3(1.0, 0.985, 0.95);
	COLOR = vec4(col, 1.0);
}
