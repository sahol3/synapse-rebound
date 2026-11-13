shader_type canvas_item;
// Screen-space radial distortion ring (Blackout Rebound, lane slams, boss kills).

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius : hint_range(0.0, 1.5) = 0.0;
uniform float thickness = 0.06;
uniform float strength = 0.03;
uniform float aspect = 1.7778;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - center;
	d.x *= aspect;
	float dist = length(d);
	float ring = 1.0 - smoothstep(0.0, thickness, abs(dist - radius));
	vec2 dir = dist > 0.0001 ? normalize(d) : vec2(0.0);
	dir.x /= aspect;
	vec2 offset = dir * ring * strength;
	vec3 col = texture(screen_texture, uv - offset).rgb;
	col += vec3(0.0, 0.6, 0.7) * ring * strength * 4.0;
	COLOR = vec4(col, 1.0);
}
