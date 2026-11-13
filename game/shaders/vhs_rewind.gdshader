shader_type canvas_item;
// Horizontal UV tear + RGB split + tracking noise for the 0.3s death rewind.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = floor(TIME * 30.0);
	float band = floor(uv.y * 40.0);
	float tear = (hash(vec2(band, t)) - 0.5) * 0.08 * intensity;
	float big_band = step(0.82, hash(vec2(floor(uv.y * 7.0), t)));
	tear += big_band * (hash(vec2(t, 3.0)) - 0.5) * 0.25 * intensity;
	uv.x += tear;
	uv.y = fract(uv.y + intensity * 0.06 * sin(TIME * 50.0));
	float split = 0.012 * intensity;
	float r = texture(screen_texture, uv + vec2(split, 0.0)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(split, 0.0)).b;
	vec3 col = vec3(r, g, b);
	float noise = hash(uv * vec2(800.0, 600.0) + t);
	col = mix(col, vec3(noise), 0.25 * intensity);
	float line = step(0.97, fract(uv.y * 3.0 - TIME * 4.0));
	col += line * 0.35 * intensity;
	col = mix(col, col * vec3(0.8, 1.0, 1.15), intensity);
	COLOR = vec4(col, 1.0);
}
