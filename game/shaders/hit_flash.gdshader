shader_type canvas_item;

uniform bool active = false;
uniform vec4 flash_color : source_color = vec4(0.0, 0.95, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV) * COLOR;
	if (active) {
		COLOR = vec4(flash_color.rgb, tex_color.a);
	} else {
		COLOR = tex_color;
	}
}
