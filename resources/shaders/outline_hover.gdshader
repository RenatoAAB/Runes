shader_type canvas_item;

uniform float outline_width : hint_range(0.0, 8.0) = 2.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.3, 1.0);
uniform bool show_outline = false;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (show_outline) {
		vec2 texel = TEXTURE_PIXEL_SIZE * outline_width;
		float outline = 0.0;
		outline = max(outline, texture(TEXTURE, UV + vec2(texel.x, 0.0)).a);
		outline = max(outline, texture(TEXTURE, UV - vec2(texel.x, 0.0)).a);
		outline = max(outline, texture(TEXTURE, UV + vec2(0.0, texel.y)).a);
		outline = max(outline, texture(TEXTURE, UV - vec2(0.0, texel.y)).a);
		outline = max(outline, texture(TEXTURE, UV + texel).a);
		outline = max(outline, texture(TEXTURE, UV - texel).a);
		outline = max(outline, texture(TEXTURE, UV + vec2(texel.x, -texel.y)).a);
		outline = max(outline, texture(TEXTURE, UV + vec2(-texel.x, texel.y)).a);

		if (color.a < 0.01 && outline > 0.01) {
			COLOR = outline_color;
			COLOR.a = outline;
		} else {
			COLOR = color;
		}
	} else {
		COLOR = color;
	}
}
