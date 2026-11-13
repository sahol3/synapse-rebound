shader_type canvas_item;
// The Echo's world-space typography: slice jitter, RGB ghosting, flicker.

uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint : source_color = vec4(1.0, 0.0, 0.2, 1.0);

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	float t = floor(TIME * 18.0);
	float slice = floor(UV.y * 6.0);
	float jitter = (hash(slice + t * 7.0) - 0.5) * 0.04 * intensity * step(0.6, hash(t + slice));
	vec2 uv = UV + vec2(jitter, 0.0);
	float a = texture(TEXTURE, uv).a;
	float a_r = texture(TEXTURE, uv + vec2(0.006 * intensity, 0.0)).a;
	float a_b = texture(TEXTURE, uv - vec2(0.006 * intensity, 0.0)).a;
	vec3 col = tint.rgb * a + vec3(1.0, 0.2, 0.3) * a_r * 0.5 + vec3(0.0, 0.9, 1.0) * a_b * 0.35;
	float flicker = 0.75 + 0.25 * step(0.2, hash(t * 1.3));
	float alpha = max(a, max(a_r, a_b) * 0.6) * COLOR.a * flicker;
	COLOR = vec4(col, alpha);
}
