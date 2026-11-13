shader_type canvas_item;
// Final screen pass, kept honest to the pixel art:
// - samples with NEAREST, so the 3x pixels are never smeared;
// - scanlines sit on the art-pixel grid (the last row of every art pixel is a touch darker),
//   instead of a sine wave that beats against it;
// - chromatic split only when something violent happens (berserk, hits), never at rest;
// - Sync tier shows as a hard 1-art-pixel frame from Overclocked up, not a glowing wash;
// - flashes are capped so a full-screen colour never hides the play.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.10;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.16;
uniform float aberration : hint_range(0.0, 0.01) = 0.0;
uniform vec4 border_color : source_color = vec4(0.0, 0.94, 1.0, 1.0);
uniform float border_strength : hint_range(0.0, 1.0) = 0.0;
uniform float berserk : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform vec2 screen_size = vec2(1152.0, 648.0);
uniform float art_px = 3.0;  // screen pixels per art pixel (Display.art)

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = uv * screen_size;
	vec3 col;
	float ab = aberration + berserk * 0.0026;
	if (ab > 0.0) {
		// Offset in whole screen pixels so the split stays crisp.
		vec2 off = vec2(floor(ab * screen_size.x + 0.5), 0.0) / screen_size;
		col = vec3(texture(screen_texture, uv + off).r, texture(screen_texture, uv).g, texture(screen_texture, uv - off).b);
	} else {
		col = texture(screen_texture, uv).rgb;
	}

	float row = mod(floor(px.y), art_px);
	col *= 1.0 - scanline_strength * step(art_px - 1.5, row) * step(1.5, art_px);

	vec2 d = uv - 0.5;
	float vig = smoothstep(0.45, 0.9, length(d * vec2(1.2, 1.0)));
	col *= 1.0 - vignette_strength * vig;

	// Tier frame: one art pixel on every edge.
	float edge = min(min(px.x, screen_size.x - px.x), min(px.y, screen_size.y - px.y));
	float frame = step(edge, art_px) * border_strength;
	vec3 bc = border_color.rgb;
	if (berserk > 0.0) {
		float flick = step(0.5, fract(TIME * 3.0));
		bc = mix(vec3(1.0, 0.6, 0.0), vec3(1.0, 0.0, 0.2), flick);
		frame = step(edge, art_px * 2.0);
	}
	col = mix(col, bc, frame);

	col = mix(col, flash_color.rgb, min(flash_color.a, 0.35));
	COLOR = vec4(col, 1.0);
}
