shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform float sea_time = 0.0;
uniform float roughness : hint_range(0.0,1.0) = 0.0;
uniform bool detailed_mesh = false;
uniform vec2 patch_center = vec2(0.0);
uniform vec2 ship_position = vec2(0.0);
uniform vec2 ship_forward = vec2(1.0,0.0);
uniform float ship_speed = 0.0;
varying vec3 world_at;
varying float swell;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
 world_at = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 vec2 p=world_at.xz;
 float a=dot(p,vec2(0.011,0.007))-sea_time*0.95;
 float b=dot(p,vec2(-0.017,0.022))-sea_time*1.45+1.3;
 float c=dot(p,vec2(0.045,-0.031))-sea_time*2.1;
 float amplitude=1.0+roughness*1.6;
 swell=(sin(a)*2.5+sin(b)*1.2+sin(c)*0.55)*amplitude;
 if(detailed_mesh) {
  vec2 local=abs(p-patch_center);
  float edge=1.0-smoothstep(1700.0,2048.0,max(local.x,local.y));
  VERTEX.y+=swell*edge;
  world_at.y+=swell*edge;
 }
}
void fragment() {
 vec2 p=world_at.xz;
 vec2 local=abs(p-patch_center);
 if(!detailed_mesh && max(local.x,local.y)<2045.0) { discard; }
 float t=sea_time;
 float variation=noise(p*0.009+vec2(-t*0.025,t*0.018));
 float a=sin(dot(p,vec2(0.023,0.041))-t*1.8+variation*4.0);
 float b=sin(dot(p,vec2(-0.043,0.029))-t*1.1+variation*3.0);
 float fine=sin(dot(p,vec2(0.13,0.19))-t*2.3);
 float crest=pow(max(0.0,a*0.55+b*0.45),10.0);
 float depth=sin(p.x*0.0013)*sin(p.y*0.0018)*0.5+0.5;
 vec3 sea=mix(vec3(0.035,0.20,0.25),vec3(0.08,0.34,0.36),depth);
 sea+=vec3(0.025,0.055,0.05)*(a*0.4+b*0.3+fine*0.15);
 sea+=vec3(0.45,0.65,0.59)*crest*(0.16+roughness*0.6);
 // Broad rolling bands and a gentle sun reflection make the swell readable.
 float slope=cos(dot(p,vec2(0.011,0.007))-t*0.95);
 sea+=vec3(0.028,0.06,0.055)*slope;
 sea+=vec3(0.09,0.15,0.13)*smoothstep(2.3,4.0,swell)*(0.12+roughness*0.6);
 vec2 boat=p-ship_position;
 float ahead=dot(boat,ship_forward);
 float across=abs(dot(boat,vec2(-ship_forward.y,ship_forward.x)));
 float bow=exp(-pow((ahead-44.0)/20.0,2.0))*exp(-pow((across-18.0)/8.0,2.0));
 float trail=exp(-pow((across-19.0+ahead*0.12)/8.0,2.0))*(1.0-smoothstep(-45.0,15.0,ahead))*smoothstep(-370.0,-80.0,ahead);
 float bubbles=(0.45+0.55*noise(p*0.15+vec2(-t*0.7,t*0.4)));
 sea=mix(sea,vec3(0.63,0.82,0.77),clamp((bow*0.85+trail*0.4)*ship_speed*bubbles,0.0,0.8));
 sea*=1.0-roughness*0.18;
 float haze=1.0-exp(-length(VERTEX.xz)*0.00021);
 ALBEDO=mix(sea,vec3(0.63,0.76,0.75),haze);
}
