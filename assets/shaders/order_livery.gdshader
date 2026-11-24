shader_type canvas_item;
uniform vec2 atlas_size;
uniform int region_count = 0;
uniform vec4 torso_regions[20];
uniform vec4 insignia_regions[20];
void fragment() {
    vec4 source = texture(TEXTURE, UV);
    vec2 pixel = UV * atlas_size;
    vec3 result = source.rgb;
    for (int i = 0; i < 20; i++) {
        if (i >= region_count) break;
        vec4 box = torso_regions[i];
        vec2 local = (pixel-box.xy)/box.zw;
        if (local.x < 0.0 || local.x > 1.0 || local.y < 0.0 || local.y > 1.0) continue;
        // Only the existing dark brown cloth is graded; preserve alpha and detail.
        float brown = smoothstep(0.035,0.09,source.r-source.g);
        brown *= smoothstep(0.015,0.045,source.g-source.b);
        brown *= 1.0-smoothstep(0.58,0.70,source.r);
        float light = dot(source.rgb,vec3(0.299,0.587,0.114));
        vec3 linen = vec3(0.94,0.89,0.75)*clamp(light*2.2+0.23,0.0,1.0);
        result = mix(result,linen,brown);
        vec4 mark = insignia_regions[i];
        vec2 at = abs((pixel-mark.xy)/mark.zw);
        float vertical = step(at.x,0.20)*step(at.y,1.0);
        float horizontal = step(at.x,0.72)*step(at.y,0.20);
        float tips = step(0.68,at.y)*step(at.y,1.0)*step(at.x,mix(0.20,0.36,(at.y-0.68)/0.32));
        tips = max(tips,step(0.50,at.x)*step(at.x,0.90)*step(at.y,0.20+(at.x-0.50)*0.35));
        float red = max(max(vertical,horizontal),tips);
        float white = max(step(at.x,0.075)*step(at.y,0.80),step(at.x,0.63)*step(at.y,0.075));
        result = mix(result,vec3(0.57,0.075,0.055)*(0.65+light),red*brown);
        result = mix(result,vec3(0.96,0.91,0.76),white*brown);
    }
    COLOR = vec4(result,source.a);
}
