shader_type canvas_item;
// Warm darkness around the shelter cutaway, lighter near the room.
void fragment() {
	vec2 p = (UV - vec2(0.5, 0.5)) * vec2(6000.0, 5000.0) + vec2(3000.0, 2500.0) - vec2(3000.0, 2500.0);
	vec2 world = UV * vec2(6000.0, 5000.0) + vec2(-3000.0, -2500.0);
	float d = length((world - vec2(96.0, 250.0)) / vec2(900.0, 560.0));
	vec3 near = vec3(0.13, 0.10, 0.075);
	vec3 far = vec3(0.045, 0.037, 0.03);
	COLOR = vec4(mix(near, far, smoothstep(0.35, 1.25, d)), 1.0);
}
