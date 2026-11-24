shader_type canvas_item;
// Flat-colour silhouette used behind a character to form its focus outline.
uniform vec4 rim : source_color = vec4(0.96, 0.84, 0.55, 0.95);
void fragment() {
	COLOR = vec4(rim.rgb, texture(TEXTURE, UV).a * rim.a * COLOR.a);
}
