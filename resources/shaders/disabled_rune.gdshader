shader_type canvas_item;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = tex_color;
	COLOR.a *= 0.5; // Semi-transparent
}
