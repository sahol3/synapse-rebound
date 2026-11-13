shader_type canvas_item;
// Screen-space scanlines, vignette, chromatic aberration, plus the Sync-tier border:
// clean cyan when Degraded, NERV crimson/amber flashing in Berserk Overdrive.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform float aberration : hint_range(0.0, 0.01) = 0.0012;
uniform vec4 border_color : source_color = vec4(0.0, 0.94, 1.0, 1.0);
uniform float border_strength : hint_range(0.0, 1.0) = 0.0;
uniform float berserk : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform vec2 screen_size = vec2(1152.0, 648.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - 0.5;
	float ab = aberration + berserk * 0.003;
	float r = texture(screen_texture, uv + d * ab * 2.0).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - d * ab * 2.0).b;
	vec3 col = vec3(r, g, b);

	float scan = 0.5 + 0.5 * sin(uv.y * screen_size.y * 3.14159);
	col *= 1.0 - scanline_strength * (1.0 - scan);

	float vig = smoothstep(0.35, 0.85, length(d * vec2(1.25, 1.0)));
	col *= 1.0 - vignette_strength * vig;

	// Tier border glow
	float edge = max(abs(d.x) * 2.0, abs(d.y) * 2.0);
	float border = smoothstep(0.86, 1.0, edge);
	vec3 bc = border_color.rgb;
	if (berserk > 0.0) {
		float flick = step(0.5, fract(TIME * 3.0));
		bc = mix(vec3(1.0, 0.6, 0.0), vec3(1.0, 0.0, 0.2), flick);
	}
	col = mix(col, bc, border * border_strength * (0.55 + 0.45 * sin(TIME * 6.0)));

	col = mix(col, flash_color.rgb, flash_color.a);
	COLOR = vec4(col, 1.0);
}
