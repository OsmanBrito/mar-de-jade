shader_type canvas_item;
uniform vec2 world_origin = vec2(0.0);
uniform vec2 canvas_size = vec2(1440.0,900.0);
uniform float world_scale = 1.0;
uniform float sea_time = 0.0;
uniform float roughness : hint_range(0.0,1.0) = 0.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
 vec2 p=world_origin+SCREEN_UV*canvas_size/world_scale;
 float t=sea_time;
 float depth=noise(p*0.0015)*0.65+noise(p*0.0041)*0.35;
 float small=noise(p*0.024+vec2(-t*0.055,t*0.035));
 float a=sin(dot(p,vec2(0.022,0.038))-t*1.05+small*2.5);
 float b=sin(dot(p,vec2(-0.033,0.026))-t*0.72+noise(p*0.012)*2.0);
 float crest=pow(max(0.0,a*0.57+b*0.43),9.0);
 float ripples=sin(dot(p,vec2(0.13,0.18))-t*1.2+small*5.0)*0.5+0.5;
 vec3 deep=vec3(0.027,0.135,0.19), jade=vec3(0.07,0.285,0.30);
 vec3 base=mix(deep,jade,depth)*(1.0-roughness*0.15);
 base+=vec3(0.035,0.085,0.08)*(a*0.2+b*0.13+ripples*0.09);
 base+=vec3(0.37,0.57,0.52)*crest*(0.10+roughness*0.55);
 COLOR=vec4(base,1.0);
}
