shader_type canvas_item;
// Tape rewind for the 0.3s death rewind and the stage-load cut. Everything moves in whole art
// pixels (3 screen px at 1152x648), so the effect tears the pixel art instead of smearing it:
// band tears, a crisp RGB offset, a rolling seam, and sparse white dropout streaks. No grain.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec2 screen_size = vec2(1152.0, 648.0);
const float ART_PX = 3.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 art = screen_size / ART_PX;                 // 384 x 216 art pixels
	vec2 ap = floor(SCREEN_UV * art);                // which art pixel we are in
	float t = floor(TIME * 24.0);

	// Tears: 6-art-pixel bands shift sideways by whole art pixels; a few bands jump far.
	float band = floor(ap.y / 6.0);
	float shift = floor((hash(vec2(band, t)) - 0.5) * 10.0 * intensity);
	if (hash(vec2(floor(ap.y / 24.0), t + 7.0)) > 0.8) {
		shift += floor((hash(vec2(t, 3.0)) - 0.5) * 60.0 * intensity);
	}
	// Rolling seam: the picture slips vertically in whole art pixels.
	float roll = floor(intensity * 8.0 * hash(vec2(t, 11.0)));
	vec2 src = vec2(ap.x + shift, mod(ap.y + roll, art.y));

	float split = floor(2.0 * intensity + 0.5);      // 0..2 art pixels
	vec2 uv = (src + 0.5) / art;
	vec2 off = vec2(split / art.x, 0.0);
	vec3 col = vec3(texture(screen_texture, uv + off).r, texture(screen_texture, uv).g, texture(screen_texture, uv - off).b);

	// Dropout: short white streaks, one art pixel tall, here and there.
	float drop = step(0.997 - 0.009 * intensity, hash(vec2(floor(ap.x / 16.0), ap.y + t * 13.0)));
	col = mix(col, vec3(0.92, 0.95, 1.0), drop * intensity);

	// Seam line where the roll wraps.
	float seam = step(abs(ap.y - (art.y - roll)), 0.5) * step(0.5, roll);
	col = mix(col, vec3(0.0), seam);

	col = mix(col, col * vec3(0.85, 1.0, 1.12), intensity * 0.6);
	COLOR = vec4(col, 1.0);
}
