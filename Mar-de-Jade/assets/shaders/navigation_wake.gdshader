shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float sea_time = 0.0;
varying vec2 world_at;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; }
void fragment() {
 float t=sea_time;
 float large=noise(world_at*0.065+vec2(-t*0.13,t*0.06));
 float small=noise(world_at*0.26+vec2(-t*0.34,t*0.17));
 float centre=UV.x-0.5+(large-0.5)*0.25+(small-0.5)*0.08;
 float feather=1.0-smoothstep(0.04,0.47,abs(centre));
 float dissolve=smoothstep(0.25+UV2.x*0.38,0.73,large*0.64+small*0.36);
 float foam=feather*dissolve*COLOR.a*0.85;
 ALBEDO=mix(vec3(0.24,0.48,0.48),vec3(0.65,0.79,0.73),small*0.5+0.5);
 ALPHA=foam;
}
