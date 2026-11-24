shader_type canvas_item;
// Per-scene colour grade over the world (the UI layer sits above it, ungraded).
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform vec3 shadow_tint = vec3(0.92, 0.97, 1.02);    // multiplies the darks
uniform vec3 highlight_tint = vec3(1.04, 1.0, 0.93);   // multiplies the lights
uniform float contrast = 1.06;
uniform float saturation = 1.04;
uniform float exposure = 1.0;
// Sunlight falling across the frame: brighter on the lit side, cooler on the far side.
uniform vec2 light_from = vec2(-0.6, -0.8);
uniform float light_strength = 0.10;
uniform vec3 light_color = vec3(1.0, 0.9, 0.72);
uniform float vignette = 0.3;
uniform vec3 vignette_color = vec3(0.05, 0.06, 0.06);

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb * exposure;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	c *= mix(shadow_tint, highlight_tint, smoothstep(0.08, 0.85, l));
	vec2 p = SCREEN_UV - 0.5;
	float lit = clamp(-dot(p, normalize(light_from)) * 1.4 + 0.5, 0.0, 1.0);
	c += light_color * c * (lit - 0.5) * 2.0 * light_strength;
	float edge = length(p * vec2(1.0, 1.25));
	c = mix(c, c * vignette_color * 4.0, smoothstep(0.38, 0.85, edge) * vignette);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
