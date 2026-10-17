shader_type canvas_item;
varying vec2 wall_at;
float grain(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(grain(i),grain(i+vec2(1,0)),f.x),mix(grain(i+vec2(0,1)),grain(i+vec2(1,1)),f.x),f.y);
}
void vertex() { wall_at=VERTEX; }
void fragment() {
	float trowel=noise(wall_at*0.045)*0.10+noise(wall_at*0.17)*0.042;
	float pores=(grain(floor(wall_at*1.8))-0.5)*0.045;
	COLOR.rgb*=0.925+trowel+pores;
}
