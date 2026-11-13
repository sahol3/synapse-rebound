shader_type canvas_item;
// Full-screen ColorRect on a CanvasLayer. Drains the world to monochrome and keeps strong reds
// during the 1.5s Blackout Rebound window.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float aberration : hint_range(0.0, 0.02) = 0.003;

void fragment() {
	vec2 uv = SCREEN_UV;
	float r = texture(screen_texture, uv + vec2(aberration * intensity, 0.0)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(aberration * intensity, 0.0)).b;
	vec3 col = vec3(r, g, b);

	// High-contrast luma, preserve strong reds and cyans
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	float red_mask = clamp((col.r - max(col.g, col.b)) * 3.0, 0.0, 1.0);
	vec3 bw_crimson = mix(vec3(luma * 0.6), vec3(1.0, 0.05, 0.2), red_mask);

	// Pulsing crimson vignette
	vec2 d = uv - 0.5;
	float vig = smoothstep(0.25, 0.75, length(d * vec2(1.4, 1.0)));
	float pulse = 0.5 + 0.5 * sin(TIME * 9.0);
	bw_crimson = mix(bw_crimson, vec3(0.45, 0.0, 0.06), vig * (0.18 + 0.12 * pulse));

	COLOR = vec4(mix(col, bw_crimson, intensity), 1.0);
}
