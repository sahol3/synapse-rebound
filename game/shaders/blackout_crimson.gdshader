shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float aberration : hint_range(0.0, 0.02) = 0.003;
uniform vec2 screen_size = vec2(1152.0, 648.0);
uniform float art_px = 3.0;

void fragment() {
	vec2 art = screen_size / art_px;
	vec2 ap = floor(SCREEN_UV * art);
	vec2 uv = (ap + 0.5) / art;
	vec2 off = vec2(step(0.5, intensity) / art.x, 0.0);
	vec3 col = vec3(texture(screen_texture, uv + off).r, texture(screen_texture, uv).g, texture(screen_texture, uv - off).b);

	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	float red_mask = clamp((col.r - max(col.g, col.b)) * 3.0, 0.0, 1.0);
	vec3 bw_crimson = mix(vec3(luma * 0.6), vec3(1.0, 0.05, 0.2), red_mask);

	float edge = min(min(ap.x, art.x - 1.0 - ap.x), min(ap.y, art.y - 1.0 - ap.y));
	float level = 0.0;
	level += step(edge, 18.0);
	level += step(edge, 9.0);
	level += step(edge, 3.0);
	float ph = fract(TIME * 1.4);
	float beat = step(ph, 0.08) + step(0.18, ph) * step(ph, 0.26);
	float dark = level / 3.0 * (0.22 + 0.18 * beat);
	bw_crimson = mix(bw_crimson, vec3(0.4, 0.0, 0.06), dark);

	COLOR = vec4(mix(col, bw_crimson, intensity), 1.0);
}
