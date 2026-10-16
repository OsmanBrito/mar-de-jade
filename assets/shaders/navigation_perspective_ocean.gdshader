shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform float sea_time = 0.0;
uniform float roughness : hint_range(0.0,1.0) = 0.0;
uniform bool detailed_mesh = false;
uniform vec2 patch_center = vec2(0.0);
uniform vec2 ship_position = vec2(0.0);
uniform vec2 ship_forward = vec2(1.0,0.0);
uniform float ship_speed = 0.0;
uniform float hull_impact = 0.0;
uniform vec4 wave_parameters[4];
uniform vec4 wave_phases;
uniform float wave_chop = 0.16;
varying vec3 world_at;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec3 noise_gradient(vec2 p) {
 vec2 i=floor(p), f=fract(p), u=f*f*(3.0-2.0*f), du=6.0*f*(1.0-f);
 float a=hash(i), b=hash(i+vec2(1,0)), c=hash(i+vec2(0,1)), d=hash(i+vec2(1,1));
 float cross_term=a-b-c+d;
 return vec3(a+(b-a)*u.x+(c-a)*u.y+cross_term*u.x*u.y,
             du.x*(b-a+cross_term*u.y),du.y*(c-a+cross_term*u.x));
}
vec3 wave_field(vec2 p) {
 float height=0.0; vec2 gradient=vec2(0.0);
 for(int i=0;i<4;i++) {
  vec4 w=wave_parameters[i]; float phase=dot(p,w.xy)-sea_time*w.z+wave_phases[i];
  height+=(sin(phase)+wave_chop*sin(phase*2.0))*w.w;
  gradient+=w.xy*(cos(phase)+wave_chop*2.0*cos(phase*2.0))*w.w;
 }
 return vec3(gradient,height)*(1.0+roughness*1.4);
}
void vertex() {
 world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 if(detailed_mesh) {
  vec2 local=abs(world_at.xz-patch_center);
  float edge=1.0-smoothstep(1700.0,2048.0,max(local.x,local.y));
  float elevation=wave_field(world_at.xz).z*edge;
  VERTEX.y+=elevation; world_at.y+=elevation;
 }
}
void fragment() {
 vec2 p=world_at.xz;
 vec2 local=abs(p-patch_center);
 if(!detailed_mesh && max(local.x,local.y)<2040.0) { discard; }
 float t=sea_time;
 float distance_to_eye=length(CAMERA_POSITION_WORLD-world_at);
 vec3 field=wave_field(p);
 // Small cross-ripples shade the real swells; detail fades before it can shimmer.
 float detail=1.0-smoothstep(300.0,2100.0,distance_to_eye);
 vec3 ripple_a=noise_gradient(p*0.065+vec2(-t*0.18,t*0.06));
 vec3 ripple_b=noise_gradient(p*0.173+vec2(t*0.11,-t*0.22)+vec2(15.7,3.2));
 vec2 ripple=(ripple_a.yz*0.10+ripple_b.yz*0.042)*detail;
 vec3 normal_world=normalize(vec3(-field.x-ripple.x,1.0,-field.y-ripple.y));
 NORMAL=normalize((VIEW_MATRIX*vec4(normal_world,0.0)).xyz);
 vec3 view_world=normalize(CAMERA_POSITION_WORLD-world_at);
 float fresnel=pow(1.0-clamp(dot(normal_world,view_world),0.0,1.0),4.0);
 float pigment=noise(p*0.0021+vec2(t*0.002,0.0));
 vec3 water=mix(vec3(0.014,0.115,0.155),vec3(0.025,0.245,0.255),pigment);
 water*=0.94+clamp(field.z/13.0,-1.0,1.0)*0.10;
 water=mix(water,vec3(0.12,0.25,0.29),fresnel*0.30);
 // Crest foam breaks into patches, rather than continuous painted stripes.
 float phase=dot(p,wave_parameters[0].xy)-t*wave_parameters[0].z+wave_phases[0];
 float top=smoothstep(0.96-roughness*0.035,0.997,sin(phase));
 vec2 crest_axis=normalize(wave_parameters[0].xy);
 vec2 foam_uv=vec2(dot(p,crest_axis)*0.28,dot(p,vec2(-crest_axis.y,crest_axis.x))*0.07);
 float breakup=smoothstep(0.58,0.79,noise(foam_uv+vec2(-t*0.30,t*0.09)));
 float foam=top*breakup*(0.02+roughness*0.30)*detail;
 // A narrow bow wave parts at the stem and runs aft down both sides of the hull.
 vec2 boat=p-ship_position;
 float ahead=dot(boat,ship_forward);
 float across=abs(dot(boat,vec2(-ship_forward.y,ship_forward.x)));
 float hull_width=max(0.7,22.0*(1.0-smoothstep(12.0,63.0,ahead))-7.0*(1.0-smoothstep(-48.0,-24.0,ahead)));
 float edge=exp(-pow((across-hull_width)/4.0,2.0));
 float length_mask=smoothstep(-57.0,-37.0,ahead)*(1.0-smoothstep(50.0,64.0,ahead));
 float stem=exp(-pow((ahead-58.0)/9.0,2.0))*exp(-pow(across/8.0,2.0));
 float bubbles=0.5+0.5*noise(p*0.20+vec2(-t*0.72,t*0.42));
 foam+=clamp((edge*length_mask*0.45+stem*0.65)*(ship_speed+hull_impact*0.45)*bubbles,0.0,0.8);
 water*=1.0-roughness*0.14;
 ALBEDO=mix(water,vec3(0.49,0.62,0.59),clamp(foam,0.0,0.78));
 METALLIC=0.0;
 ROUGHNESS=mix(0.30+roughness*0.12,0.68,clamp(foam,0.0,1.0));
 SPECULAR=0.19;
 RADIANCE=vec4(mix(vec3(0.075,0.23,0.32),vec3(0.30,0.49,0.55),fresnel),0.70);
}
